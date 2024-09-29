class Transaction < ApplicationRecord
    belongs_to :wallet

    before_create :update_available_points

    after_create_commit :process
    after_commit :check_available_points_and_update_wallet_balance, on: [:create, :update]

    enum :status, { pending: 0, completed: 1, failed: 2, spent: 3 }

    def self.spend(points, wallet)
        completed_transactions = wallet.transactions.where(status: :completed).order(timestamp: :asc)

        spent_points_by_payer = {}
        points_available = points

        ActiveRecord::Base.transaction do
            completed_transactions.each do |transaction|
                break if points_available <=0

                deduction = [points_available, transaction.available_points].min
                transaction.update(available_points: transaction.available_points - deduction)

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
            .pluck(:payer, 'SUM(available_points)::int')
            .to_h
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

    def check_available_points_and_update_wallet_balance
        if saved_change_to_attribute?('available_points') || (saved_change_to_attribute?('status') && completed?)
            ActiveRecord::Base.transaction do
                self.wallet.update_total_balance
            end
        end

        if saved_change_to_attribute?('available_points') && self.available_points <= 0
            self.spent!
        end
    end

    def update_available_points
        self.available_points = self.points
    end
end
