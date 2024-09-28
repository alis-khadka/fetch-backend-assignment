class TransactionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    transaction.completed!

    transaction.failed! if !transaction.completed?
  end
end
