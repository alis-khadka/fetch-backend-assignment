require "test_helper"

class WalletTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "method#update_total_balance: it updates the balance as per the available points from the completed transactions" do
    wallet = wallets(:one)
    wallet.update_total_balance

    current_balance = wallet.balance
    amount_to_be_added = 455

    wallet.transactions.create!(payer: "TEST", points: amount_to_be_added, timestamp: 2.hours.ago.to_s)
    perform_enqueued_jobs(at: DateTime.now)

    assert_equal wallet.reload.balance, current_balance + amount_to_be_added
  end

  test "method#update_total_balance: it does not update the balance if new transactions are not completed" do
    wallet = wallets(:one)
    wallet.update_total_balance

    current_balance = wallet.balance
    amount_to_be_added = 455

    wallet.transactions.create!(payer: "TEST", points: amount_to_be_added, timestamp: (DateTime.now + 2.hours).to_s)
    perform_enqueued_jobs(at: DateTime.now)

    assert_not_equal wallet.reload.balance, current_balance + amount_to_be_added
    assert_equal wallet.reload.balance, current_balance
  end
end
