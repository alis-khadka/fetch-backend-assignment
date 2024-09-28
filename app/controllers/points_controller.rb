class PointsController < ApplicationController
    before_action :set_wallet

    def add
        @transaction = @wallet.transactions.new(transaction_params)

        if @wallet.save
            head :ok
        else
            head :unprocessable_entity
        end
    end

    def spend
    end

    def balance

    end

    private
    def set_wallet
        @wallet = Wallet.find(params[:walled_id] || Wallet.first.id)
    end

    def transaction_params
        params.permit(:payer, :points, :timestamp)
    end
end
