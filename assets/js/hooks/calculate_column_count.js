export default {
  mounted() {
    const board = document.getElementById("board");

    const columnCount = getComputedStyle(board)
      .getPropertyValue("grid-template-columns")
      .split(" ").length;

    // Calculate how many rows we need to fill the viewport 2 times
    // This should be a large enough board to make scrolling smooth
    const rowHeightAsString = getComputedStyle(board)
      .getPropertyValue("grid-template-rows")
      .split(" ")[0];

    const rowHeight = parseInt(rowHeightAsString);

    const vh = Math.max(
      document.documentElement.clientHeight || 0,
      window.innerHeight || 0,
    );

    const rowCount = Math.round((vh / rowHeight) * 1.5);

    this.pushEvent("column-count", {
      columnCount: columnCount,
      rowCount: rowCount,
    });
  },
};
