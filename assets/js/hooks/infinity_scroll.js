export default {
  page() {
    return parseInt(this.el.dataset.page);
  },
  rootElement() {
    return (
      document.documentElement || document.body.parentNode || document.body
    );
  },
  scrollTop() {
    const { scrollTop, scrollHeight } = this.rootElement();

    return (scrollTop / scrollHeight) * 100;
  },
  scrollBottom() {
    const { scrollTop, clientHeight, scrollHeight } = this.rootElement();

    return ((scrollTop + clientHeight) / scrollHeight) * 100;
  },
  mounted() {
    this.pending = this.page();
    this.lastScrollTop = 0;
    this.lastScrollBottom = 0;
    this.topThreshold = 15;
    this.bottomThreshold = 85;

    window.addEventListener("scroll", (e) => {
      const currentTopPosition = this.scrollTop();
      const currentBottomPosition = this.scrollBottom();

      const isCloseToTop =
        currentTopPosition < this.topThreshold &&
        this.lastScrollTop >= this.topThreshold;

      const isCloseToBottom =
        currentBottomPosition > this.bottomThreshold &&
        this.lastScrollBottom <= this.bottomThreshold;

      this.lastScrollTop = currentTopPosition;
      this.lastScrollBottom = currentBottomPosition;

      console.log([
        currentTopPosition,
        currentBottomPosition,
        isCloseToBottom,
        isCloseToTop,
        this.pending,
        this.page(),
      ]);

      if (this.pending == this.page() && isCloseToBottom) {
        this.pending = this.page() + 1;
        this.pushEvent("next-page", {});
      }

      if (this.pending == this.page() && isCloseToTop) {
        this.pending = this.page() - 1;
        this.pushEvent("prev-page", {});
      }
    });
  },
  updated() {
    this.pending = this.page();
  },
};
