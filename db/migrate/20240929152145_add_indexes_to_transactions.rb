class AddIndexesToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_index :transactions, :status
    add_index :transactions, :timestamp
    add_index :transactions, :payer
  end
end
