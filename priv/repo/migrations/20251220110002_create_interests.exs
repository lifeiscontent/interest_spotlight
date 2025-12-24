defmodule InterestSpotlight.Repo.Migrations.CreateInterests do
  use Ecto.Migration

  def up do
    create table(:interests) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:interests, [:name])

    # Seed default interests
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    interests = [
      "Cinema",
      "Team Sports",
      "Traveling",
      "Cooking",
      "Gardening",
      "Graphic Design",
      "Video Gaming",
      "Painting",
      "Classic Films",
      "DIY",
      "Content Creation",
      "Photography",
      "Fishing",
      "Music",
      "Dancing",
      "Theater",
      "Sculpture",
      "Pottery",
      "Writing",
      "Drawing",
      "Crafts",
      "Fashion",
      "Interior Design",
      "Animation",
      "Film Making",
      "Stand-up Comedy",
      "Board Games",
      "Hiking",
      "Yoga",
      "Meditation"
    ]

    for name <- interests do
      execute """
      INSERT INTO interests (name, inserted_at, updated_at)
      VALUES ('#{name}', '#{now}', '#{now}')
      """
    end
  end

  def down do
    drop table(:interests)
  end
end
