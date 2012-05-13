class CreateCounter < ActiveRecord::Migration
  def up
     create_table :counters do |t|
      t.integer :id
    end
  end

  def down
    drop_table :counters
  end
end
