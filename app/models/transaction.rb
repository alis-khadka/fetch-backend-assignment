class Transaction < ApplicationRecord
    belongs_to :wallet

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
            
        else

        end
    end

    def update_wallet_balance
        Wallet.transaction do
            self.wallet.update_total_balance
        end
    end
end
