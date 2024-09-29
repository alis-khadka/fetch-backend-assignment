require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "Background job is enqueued if the timestamp is of future" do
    wallet = wallets(:one)

    assert_enqueued_with(job: TransactionJob) do
      wallet.transactions.create!(payer: "TEST", points: 200, timestamp: (DateTime.now + 2.hours).to_s)
    end
  end

  test "Background job is not enqueued if the timestamp is of not future" do
    wallet = wallets(:one)

    assert_no_enqueued_jobs(only: TransactionJob) do
      wallet.transactions.create!(payer: "TEST", points: 200, timestamp: (DateTime.now).to_s)
    end
  end

  test "method#spend: The oldest points are spent first and only the completed ones" do
    wallet = Wallet.create!
    transaction_one = wallet.transactions.create(payer: "TEST_1", points: 100, timestamp: 3.hours.ago.to_s)
    transaction_two = wallet.transactions.create(payer: "TEST_1", points: 200, timestamp: 2.hours.ago.to_s)
    transaction_three = wallet.transactions.create(payer: "TEST_2", points: 300, timestamp: 1.hour.ago.to_s)

    # These transaction will not be considered since one is in pending state and another one is already spent.
    transaction_four = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 3.hours.from_now.to_s)
    transaction_five = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 2.hours.ago.to_s, status: :spent, available_points: 0)

    expected_balance = 100 + 200 + 300

    perform_enqueued_jobs(at: DateTime.now) do
      assert_equal wallet.reload.balance, expected_balance

      Transaction.spend(400, wallet)
    end

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

  test "method#spend: Does nothing the point to be spent is more than the balance of wallet" do
    wallet = Wallet.create!
    transaction_one = wallet.transactions.create(payer: "TEST_1", points: 100, timestamp: 3.hours.ago.to_s)
    transaction_two = wallet.transactions.create(payer: "TEST_1", points: 200, timestamp: 2.hours.ago.to_s)
    transaction_three = wallet.transactions.create(payer: "TEST_2", points: 300, timestamp: 1.hour.ago.to_s)

    perform_enqueued_jobs(at: DateTime.now) do
      points_to_spend = wallet.reload.balance + 100
      current_balance = wallet.balance

      Transaction.spend(points_to_spend, wallet)

      # Nothing has been deducted from the transactions
      assert_equal wallet.reload.balance, current_balance

      # No points are used from the transactions as well
      assert_equal transaction_one.reload.available_points, transaction_one.points
      assert_equal transaction_one.reload.status, 'completed'
      assert_equal transaction_two.reload.available_points, transaction_two.points
      assert_equal transaction_two.reload.status, 'completed'
      assert_equal transaction_three.reload.available_points, transaction_three.points
      assert_equal transaction_three.reload.status, 'completed'
    end
  end

  test "method#balance_by_payer: returns the balance in a wallet using breakdown of points from distinct payers of completed transactions only" do
    wallet = Wallet.create!
    transaction_one = wallet.transactions.create(payer: "TEST_1", points: 100, timestamp: 3.hours.ago.to_s)
    transaction_two = wallet.transactions.create(payer: "TEST_1", points: 200, timestamp: 2.hours.ago.to_s)
    transaction_three = wallet.transactions.create(payer: "TEST_2", points: 300, timestamp: 1.hour.ago.to_s)

    # These transaction will not be considered since one is in pending state and another one is already spent.
    transaction_four = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 3.hours.from_now.to_s)
    transaction_five = wallet.transactions.create(payer: "HARRY", points: 500, timestamp: 2.hours.ago.to_s, status: :spent, available_points: 0)

    perform_enqueued_jobs(at: DateTime.now)

    expected_balance_breakdown = {
      "TEST_1": 100 + 200,
      "TEST_2": 300
    }.with_indifferent_access

    response = Transaction.balance_by_payers(wallet)

    assert_equal response.size, expected_balance_breakdown.size
    assert_equal response['TEST_1'], expected_balance_breakdown['TEST_1']
    assert_equal response['TEST_2'], expected_balance_breakdown['TEST_2']
  end
end
