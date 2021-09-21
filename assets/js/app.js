// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from '../vendor/topbar'
import Alpine from 'alpinejs'
import { MediaPlayerHook } from './hooks/media_player'

window.Alpine = Alpine

// Alpine.store('playerState', {
//   mediaId: null,

//   isPlaying (mediaId) {
//     return this.mediaId == mediaId
//   },

//   play (mediaId) {
//     this.mediaId = mediaId
//   },

//   pause () {
//     this.mediaId = null
//   }
// })

Alpine.data('readMore', () => ({
  canReadMore: false,
  expanded: false,
  init () {
    const {
      clientWidth,
      clientHeight,
      scrollWidth,
      scrollHeight
    } = this.$el.firstElementChild

    this.canReadMore = scrollHeight > clientHeight || scrollWidth > clientWidth
  },
  toggle () {
    this.expanded = !this.expanded
  }
}))

Alpine.data('playMediaButton', mediaId => ({
  mediaId: mediaId,
  isPlaying: false,

  // hackety hack to workaround alpine.js double-attaching event listeners
  init () {
    this.isPlaying = window.mediaPlaying == this.mediaId

    if (!this.$el.playMediaButtonInitialized) {
      this.$el.addEventListener('click', () => {
        this.playPause(this.mediaId)
      })
      this.$el.playMediaButtonInitialized = true
    }
  },

  playPause () {
    if (window.mediaPlayer) {
      // if (this.$store.playerState.isPlaying(this.mediaId)) {
      if (this.isPlaying) {
        this.isPlaying = false
        window.mediaPlayer.pause()
      } else {
        this.isPlaying = true
        window.mediaPlayer.loadAndPlayMedia(this.mediaId)
      }
    }
  }
}))

Alpine.start()

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    mediaPlayer: MediaPlayerHook
  },
  dom: {
    onBeforeElUpdated (from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#84CC16' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', info => topbar.show())
window.addEventListener('phx:page-loading-stop', info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
