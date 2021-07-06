/**
 * OffenceSearchView View controller
 */
moj.Modules.OffenceSearchView = {
  // view selector
  view: '.fx-view',

  // filters view selector
  filtersView: '.fx-filters-display',

  // page controls selector
  pageControls: '.button-holder',

  // template for each result
  template: function () {
    return ['<div class="govuk-grid-row offence-item fx-result-item">',
      '<div class="govuk-grid-column-two-thirds">',
      '<span class="govuk-body-s link-grey">',
      '<a href="#noop" class="fx-filter" data-category="{{:category.id}}">',
      '{{:category.description}}',
      '</a>&nbsp;&gt;&nbsp;',
      '<a href="#noop" class="fx-filter" data-category="{{:category.id}}" data-band="{{:band.id}}">',
      'Band:&nbsp;',
      '{{:band.description}}',
      '</a>',
      '</span></br>',
      '{{:description}}',
      '</br>',
      '<span class="govuk-body-s link-grey">{{:contrary}}</a>',
      '</div>',
      '<div class="govuk-grid-column-one-third align-right">',
      '</br>',
      '<a href="#" class="button offence-item-button set-selection" data-field="#claim_offence_id" data-value="{{:id}}">Select and continue</a>',
      '</div></div>'
    ].join('')
  },

  /**
   * init called my moj.init()
   */
  init: function () {
    const self = this

    // cache jQuery referances for each view
    this.$view = $(this.view)
    this.$filtersView = $(this.filtersView)
    this.$pageControls = $(this.pageControls)

    // Event: search results available to render
    $.subscribe('/offence/search/results/', function (e, data) {
      self.render(data)
      self.$view.show()
      self.$pageControls.toggle(false)
    })

    // Event: page control state changes
    $.subscribe('/office/search/pageControls/', function (e, state) {
      self.$pageControls.toggle(state)
    })

    // Event: clear search + results
    $.subscribe('/offence/search/clear/', function () {
      self.$view.hide()
      self.$view.find('.fx-results').empty()
      self.$view.find('.fx-filters-display p').empty()
      self.$view.find('.fx-results-found p').empty()

      if (!moj.Modules.OffenceSelectedView.isVisible()) {
        self.$pageControls.toggle(true)
      }
    })

    // Event: create rails model / submit the form
    $(document.body).on('click', '.set-selection', function (e) {
      const $element = $(e.target)
      const data = $element.data()
      const field = $(data.field)
      const value = data.value
      if (field) {
        field.attr('value', value)
        const form = field.closest('form')
        // NOTE: simulate a normal form submit
        $('<input />')
          .attr('type', 'hidden')
          .attr('name', 'commit_continue')
          .attr('value', 'Submit')
          .appendTo(form)
        form.submit()
      }
    })

    // Event: Apply filter(s)
    $('.fx-view').on('click', '.fx-filter', function (e) {
      e.preventDefault()
      const $el = $(this)
      const filter = {}
      $.each($el.data(), function (key, val) {
        filter[key + '_id'] = val
      })

      $.publish('/offence/search/filter/', filter)
    })

    // Event: Remove filters
    $('.fx-view').on('click', '.fx-clear-filters', function (e) {
      e.preventDefault()
      $.publish('/offence/search/filter/', {})
    })
  },

  /**
   * filterResults template
   * @param  {object} options Data to render to the view
   * @return {string}         View content
   */
  filterResults: function (options) {
    let str = ''

    str += 'Showing offences'

    if (options.band_id) {
      str += ' in <span class="bold-small">Band: ' + options.results[0].band.description + '</span>'
    }

    if (options.category_id) {
      str += ' in the <span class="bold-small">' + options.results[0].category.description + '</span> class. <a href="#noop" class="fx-clear-filters">Clear filters</a>.'
    }

    return str === 'Showing offences' ? '' : str
  },

  /**
   * render Render the view and attach to DOM
   * @param  {object} options results data
   */
  render: function (options) {
    const tmpl = $.templates(this.template()) // Get compiled template
    const html = tmpl.render(options.results) // Render template using data - as HTML string

    // Gives a number of the results found
    // this.$view.find('.fx-results-count span').html(data.length)
    this.$view.find('.fx-results').empty()
    this.$view.find('.fx-results').append(html)

    this.$view.find('.fx-filters-display p').empty()
    this.$view.find('.fx-filters-display p').append(this.filterResults(options))

    this.$view.find('.fx-results-found p').empty()
    this.$view.find('.fx-results-found p').append('Results found: ' + options.results.length + ' <a href="#noop" class="fx-clear-search hidden">Clear search</a>')

    this.$view.find('.fx-results').highlight(options.search_offence)
  }
}
