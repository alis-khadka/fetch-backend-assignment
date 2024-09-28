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
        points_to_spend = spend_points_params[:points].to_i

        if points > @wallet.balance
            render plain: "Insufficient points in the wallet.", status: :
        else
            response = Transaction.spend(points_to_spend, @wallet)

            render json: response, status: :ok
        end
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

    def spend_points_params
        params.permit(:points)
    end
end
