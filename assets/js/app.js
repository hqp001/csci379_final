// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/csci379_final"
import topbar from "../vendor/topbar"

const XpChart = {
  mounted() {
    this.handleEvent("chart_data", ({ labels, values }) => {
      if (this.chart) this.chart.destroy()
      const ctx = this.el.getContext("2d")
      this.chart = new window.Chart(ctx, {
        type: "bar",
        data: {
          labels,
          datasets: [{
            label: "XP Earned",
            data: values,
            backgroundColor: "rgba(79,70,229,0.7)",
            borderColor: "#4f46e5",
            borderWidth: 1,
            borderRadius: 6,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: {
            y: { beginAtZero: true, grid: { color: "rgba(0,0,0,0.05)" } },
            x: { grid: { display: false } }
          }
        }
      })
    })
  },
  destroyed() { this.chart?.destroy() }
}

const AccuracyChart = {
  mounted() {
    this.handleEvent("accuracy_data", ({ correct, incorrect }) => {
      if (this.chart) this.chart.destroy()
      const ctx = this.el.getContext("2d")
      this.chart = new window.Chart(ctx, {
        type: "doughnut",
        data: {
          labels: ["Correct", "Incorrect"],
          datasets: [{
            data: [correct, incorrect],
            backgroundColor: ["#10b981", "#ef4444"],
            borderWidth: 0,
            hoverOffset: 6,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          cutout: "68%",
          plugins: {
            legend: { position: "bottom", labels: { boxWidth: 10, font: { size: 11 }, padding: 10 } }
          }
        }
      })
    })
  },
  destroyed() { this.chart?.destroy() }
}

// Dark mode toggle — event-delegated so it survives LiveView DOM patching
window.addEventListener("click", (e) => {
  if (e.target.closest("#dark-mode-toggle")) {
    const isDark = document.documentElement.classList.toggle("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
  }
  // Close user dropdown when clicking outside
  const dropdown = document.getElementById("user-dropdown")
  if (dropdown && !dropdown.classList.contains("hidden") && !e.target.closest("#user-menu")) {
    dropdown.classList.add("hidden")
  }
})

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, XpChart, AccuracyChart},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

