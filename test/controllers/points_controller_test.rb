require "test_helper"

class PointsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "#home: checks the health of api server" do
    get root_url

    assert_response :ok
    assert_equal @response.parsed_body[:message], 'Welcome to wallet api.'
  end

  test "#add: adds a transaction successfully" do
    wallet = wallets(:one)
    timestamp = DateTime.now.to_s

    post points_add_url, params: {
      payer: "PEARL",
      points: 200,
      timestamp: timestamp
    }

    assert_response :ok
    assert wallet.transactions.find_by(timestamp: DateTime.parse(timestamp), payer: "PEARL", points: 200)
  end

  test "#add: adds a transaction successfully but the transaction is not reflected in the wallet balance if the timestamp is of future" do
    wallet = wallets(:one)
    timestamp = 2.hours.from_now.to_s

    current_balance = wallet.balance

    perform_enqueued_jobs(at: DateTime.now) do
      assert_enqueued_with(job: TransactionJob) do
        post points_add_url, params: {
          payer: "PEARL",
          points: 200,
          timestamp: timestamp
        }
      end
    end

    new_transaction = wallet.transactions.find_by(timestamp: DateTime.parse(timestamp), payer: "PEARL", points: 200)

    assert_response :ok
    assert new_transaction

    # The transaction is still pending
    assert_equal new_transaction.status, 'pending'
    assert_equal wallet.reload.balance, current_balance
  end

  test "#add: adds a transaction successfully and the transaction is reflected in the wallet balance if the timestamp is not of future" do
    wallet = wallets(:one)
    timestamp = DateTime.now.to_s

    current_balance = wallet.balance

    perform_enqueued_jobs(at: DateTime.now) do
      assert_no_enqueued_jobs(only: TransactionJob) do
        post points_add_url, params: {
          payer: "PEARL",
          points: 200,
          timestamp: timestamp
        }
      end
    end

    new_transaction = wallet.transactions.find_by(timestamp: DateTime.parse(timestamp), payer: "PEARL", points: 200)

    assert_response :ok
    assert new_transaction

    # The transaction is completed
    assert_equal new_transaction.status, 'completed'
    assert_not_equal wallet.reload.balance, current_balance
    assert_equal wallet.balance, current_balance + 200
  end

  test "#add: return error message if the timestamp is missing" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: "PEARL",
        points: 200
      }
    end

    assert_response :bad_request
    assert_equal 'Timestamp key is missing.', @response.parsed_body
  end

  test "#add: return error message if the timestamp is invalid" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: "PEARL",
        points: 200,
        timestamp: 'dsalkjflkkdjsfalk'
      }
    end

    assert_response :bad_request
    assert_equal 'Invalid timestamp.', @response.parsed_body
  end

  test "#add: return error message if payer is missing" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        points: 200,
        timestamp: DateTime.now.to_s
      }
    end

    assert_response :bad_request
    assert_equal 'Payer is missing or empty.', @response.parsed_body
  end

  test "#add: return error message if payer is empty" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: '',
        points: 200,
        timestamp: DateTime.now.to_s
      }
    end

    assert_response :bad_request
    assert_equal 'Payer is missing or empty.', @response.parsed_body
  end

  test "#add: return error message if points is missing" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: 'TEST',
        timestamp: DateTime.now.to_s
      }
    end

    assert_response :bad_request
    assert_equal 'Points is missing.', @response.parsed_body
  end

  test "#add: return error message if points is negative" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: 'TEST',
        points: -200,
        timestamp: DateTime.now.to_s
      }
    end

    assert_response :bad_request
    assert_equal 'Points value cannot be negative or zero.', @response.parsed_body
  end

  test "#add: return error message if points is zero" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      post points_add_url, params: {
        payer: 'TEST',
        points: 0,
        timestamp: DateTime.now.to_s
      }
    end

    assert_response :bad_request
    assert_equal 'Points value cannot be negative or zero.', @response.parsed_body
  end

  test "#spend: succefully spends the points if it is less than or equal to the wallet balance" do
    wallet = Wallet.create!
    transaction_one = wallet.transactions.create(payer: "TEST_1", points: 100, timestamp: 3.hours.ago.to_s)
    transaction_two = wallet.transactions.create(payer: "TEST_1", points: 200, timestamp: 2.hours.ago.to_s)
    transaction_three = wallet.transactions.create(payer: "TEST_2", points: 300, timestamp: 1.hour.ago.to_s)

    # These transaction will not be considered since one is in pending state and another one is already spent.
    transaction_four = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 3.hours.from_now.to_s)
    transaction_five = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 2.hours.ago.to_s, status: :spent, available_points: 0)

    expected_balance = 100 + 200 + 300

    perform_enqueued_jobs(at: DateTime.now) do
      assert_equal expected_balance, wallet.reload.balance

      post points_spend_url, params: { points: 400, wallet_id: wallet.id }
    end

    assert_response :ok

    expected_response = [
      {"payer": "TEST_1", "points": -300},
      {"payer": "TEST_2", "points": -100}
    ]

    assert_equal expected_response.find { |item| item[:payer] == "TEST_1"}[:points], @response.parsed_body.find {|item| item["payer"] == "TEST_1"}["points"]
    assert_equal expected_response.find { |item| item[:payer] == "TEST_2"}[:points], @response.parsed_body.find {|item| item["payer"] == "TEST_2"}["points"]

    # 400 has been deducted from the wallet after spending
    expected_balance = expected_balance - 400
    assert_equal wallet.reload.balance, expected_balance

    # transaction_one and transaction_two are fully used with status :spent
    assert_equal transaction_one.reload.available_points, 0
    assert_equal transaction_one.reload.status, 'spent'
    assert_equal transaction_two.reload.available_points, 0
    assert_equal transaction_two.reload.status, 'spent'
    
    # transaction_three is partially spent
    expected_points = 200
    assert_equal transaction_three.reload.available_points, expected_points
    assert_not_equal transaction_three.reload.status, 'spent'
  end

  test "#spend: return error message if points is missing" do
    wallet = wallets(:one)

    perform_enqueued_jobs(at: DateTime.now) do
      post points_spend_url
    end

    assert_response :bad_request
    assert_equal 'Points is missing.', @response.parsed_body
  end

  test "#spend: return error message if points is not integer" do
    wallet = wallets(:one)

    perform_enqueued_jobs(at: DateTime.now) do
      post points_spend_url, params: { points: 'dfas;' }
    end

    assert_response :bad_request
    assert_equal 'Points value should be integer.', @response.parsed_body
  end

  test "#spend: return error message if points is negative" do
    wallet = wallets(:one)

    perform_enqueued_jobs(at: DateTime.now) do
      post points_spend_url, params: { points: -300 }
    end

    assert_response :bad_request
    assert_equal 'Points value cannot be negative or zero.', @response.parsed_body
  end

  test "#spend: return error message if points is zero" do
    wallet = wallets(:one)

    perform_enqueued_jobs(at: DateTime.now) do
      post points_spend_url, params: { points: 0 }
    end

    assert_response :bad_request
    assert_equal 'Points value cannot be negative or zero.', @response.parsed_body
  end

  test "#spend: return error message if the provided points is more than the balance in wallet" do
    wallet = wallets(:one)

    perform_enqueued_jobs(at: DateTime.now) do
      post points_spend_url, params: { points: wallet.balance + 200 }
    end

    assert_response :bad_request
    assert_equal 'Insufficient points in the wallet.', @response.parsed_body
  end

  test "#balance: return the breakdown of points from distinct payers of completed transactions" do
    wallet = Wallet.create!
    transaction_one = wallet.transactions.create(payer: "TEST_1", points: 100, timestamp: 3.hours.ago.to_s)
    transaction_two = wallet.transactions.create(payer: "TEST_1", points: 200, timestamp: 2.hours.ago.to_s)
    transaction_three = wallet.transactions.create(payer: "TEST_2", points: 300, timestamp: 1.hour.ago.to_s)

    # These transaction will not be considered since one is in pending state and another one is already spent.
    transaction_four = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 3.hours.from_now.to_s)
    transaction_five = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 2.hours.ago.to_s, status: :spent, available_points: 0)

    perform_enqueued_jobs(at: DateTime.now)

    get points_balance_url, params: { wallet_id: wallet.id }

    assert_response :ok

    expected_balance_breakdown = {
      "TEST_1": 100 + 200,
      "TEST_2": 300
    }.with_indifferent_access

    assert_equal expected_balance_breakdown.size, @response.parsed_body.size
    assert_equal expected_balance_breakdown['TEST_1'], @response.parsed_body['TEST_1']
    assert_equal expected_balance_breakdown['TEST_2'], @response.parsed_body['TEST_2']
  end
end
