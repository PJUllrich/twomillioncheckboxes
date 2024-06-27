export default {
  mounted() {
    this.spinner = document.getElementById("loading-spinner");

    window.addEventListener("phx:page-loading-start", (_info) => {
      this.spinner.classList.remove("hidden");
    });
    window.addEventListener("phx:page-loading-stop", (_info) => {
      this.spinner.classList.add("hidden");
    });
  },
};
