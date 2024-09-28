class Wallet < ApplicationRecord
    has_many :transactions

    def update_total_balance
        new_total = self.transactions
            .where(status: :completed)
            .sum(:availabe_points)

        self.update!
    end
end
