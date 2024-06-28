export default {
  mounted() {
    const board = document.getElementById("board");

    const columnCount = getComputedStyle(board)
      .getPropertyValue("grid-template-columns")
      .split(" ").length;

    this.pushEvent("column-count", columnCount);
  },
};
