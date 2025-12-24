defmodule InterestSpotlight.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections) do
      add :requester_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:connections, [:requester_id])
    create index(:connections, [:user_id])
    create index(:connections, [:status])
    create unique_index(:connections, [:requester_id, :user_id])
  end
end
