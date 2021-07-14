/* global Bloodhound */

moj.Modules.Autocomplete = {
  displayNameKey: 'displayName',
  selectSelector: 'select.typeahead',
  wrapperSelector: '.js-typeahead',

  /**
   * init called by moj init routine
   */
  init: function () {
    if (this.doKickoff()) {
      this.typeaheadKickoff()
      this.typeaheadBindEvents()
    }
    this.initAutoCompleteTextFields()
  },

  doKickoff: function () {
    return $(this.selectSelector).length
  },

  bh: function (data) {
    const self = this
    if (!data || !data.local) {
      throw Error('Params missing..')
    }
    return new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace(self.displayNameKey),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      identify: function (obj) {
        return obj[self.displayNameKey]
      },
      local: data.local
    })
  },

  sourceWithDefaults: function (q, sync, typeaheadList) {
    if (q === '') {
      sync(typeaheadList.all())
    } else {
      typeaheadList.search(q, sync)
    }
  },

  typeaheadBindEvents: function (selector) {
    const self = this

    selector = selector || this.wrapperSelector

    $(selector).on('typeahead:select', 'input.typeahead', function (e, obj) {
      self.typeaheadSetSelectedProp(e, obj[self.displayNameKey])
    })

    $(selector).on('typeahead:change', 'input.typeahead', function (e, str) {
      self.typeaheadSetSelectedProp(e, str)
    })

    $(selector).on('typeahead:autocomplete', 'input.typeahead', function (e, obj) {
      self.typeaheadSetSelectedProp(e, obj[self.displayNameKey])
    })
  },

  typeaheadSetSelectedProp: function (e, str) {
    const $wrapper = $(e.delegateTarget)
    const selectedTextString = $wrapper.find('select.typeahead option:selected').text()

    if (str === '' || !str) {
      $wrapper.find('select.typeahead').prop('selectedIndex', 0).change()
      return
    }

    if (str !== selectedTextString) {
      $wrapper.find('select.typeahead option').filter(function () {
        return $.trim($(this).text()) === $.trim(str)
      }).prop('selected', true).change()
    }
  },

  typeaheadKickoff: function (selector) {
    const self = this
    selector = selector || this.selectSelector

    $(selector).each(function applyTypeahead () {
      const $select = $(this)
      const $input = $('<input />')
      const typeaheadList = self.bh({
        local: self.typeaheadBuildDataFromSelect($select)
      })

      $select.attr('tabindex', -1)

      self.typeaheadPrepInputAndAttach($select, $input).then(function () {
        self.typeaheadInit($input, typeaheadList)
      })
    })
  },

  typeaheadInit: function ($input, typeaheadList) {
    const self = this

    if (!typeaheadList || !$input) {
      throw Error('Missing params')
    }

    if (!$input.typeahead) {
      throw Error('Missing jquery plugin')
    }

    $input.typeahead({
      minLength: 0,
      highlight: true
    }, {
      display: self.displayNameKey,
      limit: 1000,
      source: function (q, sync) {
        return self.sourceWithDefaults(q, sync, typeaheadList)
      },
      templates: {
        empty: [
          '<div class="empty-message">',
          'No Results, please check your spelling',
          '</div>'
        ].join('\n')
      }
    })
  },

  typeaheadPrepInputAndAttach: function ($select, $input) {
    const defer = $.Deferred()
    const $parent = $select.parent() // :(
    const promise1 = this.typeaheadSetInputValueFromDom($select, $input)
    const promise2 = this.typeaheadCopySelectAttrsToInput($select, $input)

    $.when(promise1, promise2).done(function () {
      $parent.find('select.typeahead').after($input)
      defer.resolve()
    })

    return defer.promise()
  },

  typeaheadSetInputValueFromDom: function ($select, $input) {
    const defer = $.Deferred()

    $input.val($select.find('option:selected').text())

    defer.resolve($input)
    return defer.promise()
  },

  typeaheadCopySelectAttrsToInput: function ($select, $input) {
    const defer = $.Deferred()
    $.each($select.prop('attributes'), function applyAttributes () {
      if (this.name === 'name') {
        return
      }

      if (this.name === 'id') {
        return $input.attr(this.name, this.value + '_input')
      }
      $input.attr(this.name, this.value)
    })

    $input.removeClass('js-hidden')
    $input.addClass('form-control')
    $input.attr('tabindex', 0)
    $input.attr('autocomplete', 'off')
    defer.resolve($input)

    return defer.promise()
  },

  typeaheadBuildDataFromSelect: function ($select) {
    const self = this
    return $select.find('option').map(function mapOptions () {
      const obj = {}
      if (this.value === '') {
        return // eslint-disable-line
      }

      obj.id = this.value
      obj[self.displayNameKey] = this.text
      return obj
    }).get()
  },

  // TODO: this should be related to the autocomplete
  // module currently being used. Right now don't really
  // know how to do that easily :(
  suggestionTemplate: function (data) {
    return ['<div class="govuk-grid-row offence-item">',
      '<div class="govuk-grid-column-two-thirds">',
      '<span class="govuk-body-s link-grey">',
      data.category.description,
      '&nbsp;&gt;&nbsp;Band:&nbsp;',
      data.band.description,
      '</span></br>',
      data.description,
      '</br>',
      '<span class="govuk-body-s link-grey">' + data.contrary + '</a>',
      '</div>',
      '<div class="govuk-grid-column-one-third align-right">',
      '</br>',
      '<a href="#" class="button offence-item-button set-selection" data-field="#claim_offence_id" data-value="' + data.id + '">Select and continue</a>',
      '</div></div>'
    ].join('')
  },

  emptyTemplate: function () {
    return ['<div class="empty-message">',
      'No Results, please check your spelling',
      '</div>'
    ].join('')
  },

  initAutoCompleteTextFields: function () {
    const self = this

    $('.typeahead-textfield').each(function () {
      const $element = $(this)
      const data = $element.data()
      const dataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
          url: data.url,
          prepare: function (query, settings) {
            // TODO: URL for now already has a base query string
            // hence this just appending extra query params
            settings.url += '&' + $element.attr('name') + '=' + query
            return settings
          }
        }
      })
      $element.typeahead({
        hint: false,
        highlight: true,
        menu: $(data.menu),
        minLength: 3
      }, {
        name: $element.attr('name'),
        display: 'value',
        limit: 1000,
        source: dataSource,
        templates: {
          empty: self.emptyTemplate(),
          suggestion: function (data) {
            return self.suggestionTemplate(data)
          }
        }
      })
    })
  }
}
