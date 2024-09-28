class Transaction < ApplicationRecord
    belongs_to :wallet

    after_commit :process, on: [:create, :update]
    after_commit :update_wallet_balance, on: [:create, :update]

    enum status: {
        pending: 0,
        completed: 1,
        failed: 2,
        spent: 3
    }

    private
    def process
        if self.timestamp.future?
            TransactionJob.set(wait_until: self.timestamp).perform_later(self.id)
        else
            begin
                self.completed!

                self.failed! if !self.completed?
            rescue ActiveRecord::RecordInvalid => error
                Rails.logger.error "Failed to process transaction with id: #{self.id} and error: #{error.message}."
            end
        end
    end

    def update_wallet_balance
        if saved_change_to_status? && completed?
            Wallet.transaction do
                self.wallet.update_total_balance
            end
        end
    end
end
