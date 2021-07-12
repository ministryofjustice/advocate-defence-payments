const { environment } = require('@rails/webpacker')
const ConcatPlugin = require('webpack-concat-plugin')

environment.plugins.append('ConcatPlugin', new ConcatPlugin({
  uglify: true,
  sourceMap: true,
  outputPath: 'js',
  fileName: 'application.bundle.js',
  filesToConcat: [
    'jquery',
    'jquery-migrate',
    'jquery-ujs',
    'jquery.iframe-transport',
    'dropzone',
    'govuk_frontend_toolkit/javascripts/govuk/stick-at-top-when-scrolling.js',
    'govuk_frontend_toolkit/javascripts/govuk/stop-scrolling-at-footer.js',
    'jquery-accessible-accordion-aria',
    'jsrender',
    'jquery-highlight',
    'jquery-throttle-debounce',
    'accessible-autocomplete',
    './app/webpack/javascripts/vendor/**/*',
    './app/webpack/javascripts/modules/**/*',
    './app/webpack/javascripts/plugins/**/*',
    './app/webpack/javascripts/application.js'
  ]
}))

module.exports = environment
