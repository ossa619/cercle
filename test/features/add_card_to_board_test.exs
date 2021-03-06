defmodule CercleApi.AddCardToBoardTest do
  use CercleApi.FeatureCase
  setup %{session: session} do
    {user, company} = create_user_with_company()
    board = CercleApi.Factory.insert(:board,
      name: "Test Board", company: company)
    CercleApi.Factory.insert(:board_column, board: board)
    {:ok, session: session, user: user, company: company, board: board}
  end

  test "Add new card without contact", %{
    session: session, user: user, company: company, board: board} do
    session
    |> sign_in(user.login, "1234")
    |> visit("/company/#{company.id}/board/#{board.id}")
    |> click(css(".add-card"))
    |> fill_in(text_field("Name of the Card"), with: "Test Card")
    |> find(css(".new-card-form"), fn(form) -> click(form, button("Save")) end)
    |> assert_has(css("body.async-ready"))
    |> assert_has(css("#board_columns", text: "Test Card"))
  end

  test "Add new card with contact", %{
    session: session, user: user, company: company} do
    CercleApi.Factory.insert(:contact,
      first_name: "John", last_name: "Doe",
      user: user, company: company)
    board = CercleApi.Factory.insert(:board, type_of_card: 1,
      name: "Test Board", company: company)
    CercleApi.Factory.insert(:board_column, board: board)

    session
    |> sign_in(user.login, "1234")
    |> visit("/company/#{company.id}/board/#{board.id}")
    |> click(css(".add-card"))
    |> find(css(".add-contact"), fn(contact_form) ->
      contact_form
      |> fill_in(css("input[type='search']"), with: "John")
      |> click(css(".dropdown-menu a", text: "John Doe" ))
    end)
    |> find(css(".new-card-form"), fn(form) -> click(form, button("Save")) end)
    |> assert_has(css("body.async-ready"))
    |> assert_has(css("#board_columns", text: "John Doe"))
  end

  test "Cancel should reset new card in Project Board", %{
    session: session, user: user, company: company, board: board} do
    session
    |> sign_in(user.login, "1234")
    |> visit("/company/#{company.id}/board/#{board.id}")
    |> click(css(".add-card"))
    |> fill_in(text_field("Name of the Card"), with: "Test Card")
    |> click(css(".new-card-form .btn-link", text: "Cancel" ))
    |> assert_has(css("body.async-ready"))
    |> take_screenshot
    |> click(css(".add-card"))
    |> assert_has(css("input.card-name", with: ""))
  end

  test "Cancel should reset new card People Board", %{
    session: session, user: user, company: company} do
    board = CercleApi.Factory.insert(:board, type_of_card: 1,
      name: "Test Board", company: company)
    session
    |> sign_in(user.login, "1234")
    |> visit("/company/#{company.id}/board/#{board.id}")
    |> click(css(".add-card"))
    |> fill_in(css("input[type='search']"), with: "New contact")
    |> click(css(".dropdown-menu a", text: "New contact" ))
    |> fill_in(css("input[type=email]"), with: "abc@xyz.com")
    |> fill_in(css("input[type=phone]"), with: "123456789")
    |> click(css(".new-card-form .btn-link", text: "Cancel" ))
    |> assert_has(css("body.async-ready"))
    |> take_screenshot
    |> click(css(".add-card"))
    |> assert_has(css("input[type=email]", with: ""))
    |> assert_has(css("input[type=phone]", with: ""))
  end
end
