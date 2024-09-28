class Transaction < ApplicationRecord
    belongs_to :wallet

    before_create :update_available_points

    after_create :process
    after_commit :update_wallet_balance, on: [:create, :update]
    after_update :check_available_points

    enum status: {
        pending: 0,
        completed: 1,
        failed: 2,
        spent: 3
    }

    def self.spend(points, wallet)
        completed_transactions = wallet.transactions.where(status: :completed).order(timestamp: :asc)

        spent_points_by_payer = {}
        points_available = points

        ActiveRecord::Base.transaction do
            completed_transactions.each do |transaction|
                break if points_available <=0

                deduction = [points_available, transaction.availabe_points].min
                transaction.update!(availabe_points: transaction.availabe_points - deduction)

                points_available -= deduction

                if spent_points_by_payer[transaction.payer]
                    spent_points_by_payer[transaction.payer] += deduction
                else
                    spent_points_by_payer[transaction.payer] = deduction
                end
            end
        end

        spent_points_by_payer.map { |key, value| {payer: key, points: -value} }
    end

    def self.balance_by_payers(wallet)
        wallet.transactions
            .where(status: :completed)
            .group(:payer)
            .order(payer: :asc)
            .select(:payer, 'SUM(available_points)')
            .size
    end

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
            ActiveRecord::Base.transaction do
                self.wallet.update_total_balance
            end
        end
    end

    def update_available_points
        self.availabe_points = self.points
    end

    def check_available_points
        if saved_change_to_available_points? && self.availabe_points <= 0
            self.spent!
        end
    end
end
