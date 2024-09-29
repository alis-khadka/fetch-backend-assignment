class Wallet < ApplicationRecord
    has_many :transactions

    def update_total_balance
        new_total = self.transactions
            .where(status: :completed)
            .sum(:available_points)

        self.update(balance: new_total)
    end
end
