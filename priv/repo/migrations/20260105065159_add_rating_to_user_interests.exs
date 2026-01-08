defmodule InterestSpotlight.Repo.Migrations.AddRatingToUserInterests do
  use Ecto.Migration

  def change do
    alter table(:user_interests) do
      add :rating, :integer
    end
  end
end
