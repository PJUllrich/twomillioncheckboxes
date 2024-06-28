# A clone of [OneMillionCheckboxes](https://onemillioncheckboxes.com), written in Elixir and scaled to TWO million checkboxes ;)

You can play with it on [twomillioncheckboxes.com](https://twomillioncheckboxes.com)

## Open Issues

This project is currently work-in-progress. There are a few major problems that need fixing. PRs and suggestions are much appreciated:

* [x] Fix checkbox update payload.
    * Currently, whenever a checkbox changes, all players receive an `:update` event and patch their state of the game. But the `PageLive` LiveView currently stores the visible checkboxes as one long list. Whenever that list is updated **all** checkboxes are re-rendered, leading to a message payload of ~56kb for every checkbox change.
    * This needs to be optimised. `LiveComponents` *might* help, but we can't afford to spin up 1000s of processes for every player.
    * **Fixed**: By moving to streams, I could use `stream_insert/3` to update individual checkboxes. The payload size went down to 152 bytes per update.
* [x] Fix UX issues with inifinity scrolling
    * The current scroll behaviour is jumpy and doesn't work for scrolling to the top. This needs fixing by somebody smarter than me (please).
    * **Fixed**: I tuned the padding of the board and added enough checkboxes so that the infinity scrolling works now. Ideally, the `prev-page` and `next-page` events would kick not only when the end of the viewport is reached, but when e.g. 115% of the viewport is reached. That way, the loading would happen just a bit earlier and become just a bit smoother. But it's okay as it is right now.
* [x] (Maybe) get Streams to work.
    * My first implementation was using LiveView streams. That worked alright, but I could not remove old elements, so only new ones were added. When I added a `limit: -3000` to the `stream(:checkboxes, checkboxes, at: at, limit: limit)` call in `PageStreamLive`, the re-render time in the client went from <10ms to almost a second. If we could fix that, streams could work BUT:
    * How can we handle updates to single elements inside a stream? That's the same issue as with the current `assign` implementation in `PageLive`. We'd need to re-render the whole board.
    * **Fixed**: By reducing the size down to batches of `500` checkboxes, the streams worked eventually. The biggest problem here was to get the infinity scrolling to work with larger displays. I needed to render e.g. 2000 elements at first to fill the whole screen. If i didn't fill it, the `prev-page` and `next-page` would fire as soon as I'd scroll down one percent. The board needed to be big enough to span the whole window.
* [x] Fix the shift of the board when the rows have an uneven numer of checkboxes
    * **Fixed**: I calculate now the number of columns in the client using a Hook and send back that `column_count` to the LiveView. When I fetch new data, I only fetch "full rows" (e.g. if there are 18 columns, I'd only fetch 18 * 27 = 486 checkboxes instead of 500). I don't remove or add "partial rows" this way which prevents a layout shift and keeps all checkboxes in place.
* [x] Ignore events for checkboxes that are not currently visible on the player's board. Currently, LiveView will add them to the board, which is weird.
* [ ] General QA and testing would be very much appreciated!

## Optional Fixes
These fixes are nice-to-have and might become important in the future.
* [x] Replace the `MapSet` in the `State` GenServer with an `:ets` table to allow better read concurrency.
* [x] When using `:ets`, use `tab2List` to dump the state into the db instead if passing a potentially very long array from the `State` to the `Dumper` genserver.
* [ ] Store current position as URL parameter to prevent board reload for all users when the server restarts

## Local development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
