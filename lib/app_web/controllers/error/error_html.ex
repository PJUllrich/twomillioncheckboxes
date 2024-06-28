defmodule AppWeb.ErrorHTML do
  use AppWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/vcp_web/controllers/error_html/404.html.heex
  #   * lib/vcp_web/controllers/error_html/500.html.heex
  #
  embed_templates "templates/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

# Return a 400 instead of raising an Exception if a request has
# the wrong Mime format (e.g. "text")
defimpl Plug.Exception, for: Phoenix.NotAcceptableError do
  def status(_exception), do: 400
  def actions(_exception), do: []
end

# Return a 400 instead of raising an Exception if a request has
# an invalid CSRF token.
defimpl Plug.Exception, for: Plug.CSRFProtection.InvalidCSRFTokenError do
  def status(_exception), do: 400
  def actions(_exception), do: []
end
