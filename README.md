# A clone of [OneMillionCheckboxes](https://onemillioncheckboxes.com), written in Elixir and scaled to TWO million checkboxes ;)

You can play with it on [twomillioncheckboxes.com](https://twomillioncheckboxes.com)

## Open Issues

This project is currently work-in-progress. There are a few major problems that need fixing. PRs and suggestions are much appreciated:

* [ ] Fix checkbox update payload.
    * Currently, whenever a checkbox changes, all players receive an `:update` event and patch their state of the game. But the `PageLive` LiveView currently stores the visible checkboxes as one long list. Whenever that list is updated **all** checkboxes are re-rendered, leading to a message payload of ~56kb for every checkbox change.
    * This needs to be optimised. `LiveComponents` *might* help, but we can't afford to spin up 1000s of processes for every player.
* [ ] Fix UX issues with inifinity scrolling
    * The current scroll behaviour is jumpy and doesn't work for scrolling to the top. This needs fixing by somebody smarter than me (please).
* [ ] (Maybe) get Streams to work.
    * My first implementation was using LiveView streams. That worked alright, but I could not remove old elements, so only new ones were added. When I added a `limit: -3000` to the `stream(:checkboxes, checkboxes, at: at, limit: limit)` call in `PageStreamLive`, the re-render time in the client went from <10ms to almost a second. If we could fix that, streams could work BUT:
    * How can we handle updates to single elements inside a stream? That's the same issue as with the current `assign` implementation in `PageLive`. We'd need to re-render the whole board.
* [ ] General QA and testing would be very much appreciated!

## Optional Fixes
These fixes are nice-to-have and might become important in the future.
* [ ] Replace the `MapSet` in the `State` GenServer with an `:ets` table to allow better read concurrency.

## Local development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
