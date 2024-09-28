class CreateWallets < ActiveRecord::Migration[7.2]
  def change
    create_table :wallets do |t|
      t.bigint :balance, default: 0

      t.timestamps
    end
  end
end
