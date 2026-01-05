defmodule InterestSpotlight.BackofficeFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `InterestSpotlight.Backoffice` context.
  """

  import Ecto.Query

  alias InterestSpotlight.Backoffice
  alias InterestSpotlight.Backoffice.Scope

  def unique_admin_email, do: "admin#{System.unique_integer()}@example.com"
  def valid_admin_password, do: "hello world!"

  def valid_admin_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_admin_email()
    })
  end

  def unconfirmed_admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> valid_admin_attributes()
      |> Backoffice.register_admin()

    admin
  end

  def admin_fixture(attrs \\ %{}) do
    admin = unconfirmed_admin_fixture(attrs)

    token =
      extract_admin_token(fn url ->
        Backoffice.deliver_login_instructions(admin, url)
      end)

    {:ok, {admin, _expired_tokens}} =
      Backoffice.login_admin_by_magic_link(token)

    admin
  end

  def admin_scope_fixture do
    admin = admin_fixture()
    admin_scope_fixture(admin)
  end

  def admin_scope_fixture(admin) do
    Scope.for_admin(admin)
  end

  def set_password(admin) do
    {:ok, {admin, _expired_tokens}} =
      Backoffice.update_admin_password(admin, %{password: valid_admin_password()})

    admin
  end

  def extract_admin_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    InterestSpotlight.Repo.update_all(
      from(t in Backoffice.AdminToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_admin_magic_link_token(admin) do
    {encoded_token, admin_token} = Backoffice.AdminToken.build_email_token(admin, "login")
    InterestSpotlight.Repo.insert!(admin_token)
    {encoded_token, admin_token.token}
  end

  def offset_admin_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    InterestSpotlight.Repo.update_all(
      from(ut in Backoffice.AdminToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
