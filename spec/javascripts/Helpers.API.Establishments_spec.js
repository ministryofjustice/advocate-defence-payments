describe('Helpers.API.Establishments.js', function () {
  const helper = moj.Helpers.API.Establishments

  it('should exist', function () {
    expect(moj.Helpers.API.Establishments).toBeDefined()
  })

  it('should have a `loadData` on the API', function () {
    expect(helper.loadData).toBeDefined()
  })

  describe('...loadData', function () {
    beforeEach(function () {
      $('body').append('<div id="expenses" data-feature-distance="true">here</div>')
    })
    afterEach(function () {
      $('#expenses').remove()
    })

    it('should call `loadData` if the DOM triggers are in place', function () {
      const deferred = $.Deferred()
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      helper.init().then(function () {
        expect(moj.Helpers.API._CORE.query).toHaveBeenCalledWith({
          url: '/establishments.json',
          type: 'GET',
          dataType: 'json'
        })
      })
      deferred.resolve([])
    })

    it('should call `$.publish` the success event', function () {
      const deferred = $.Deferred()
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      spyOn($, 'publish')

      helper.init().then(function () {
        expect($.publish).toHaveBeenCalledWith('/API/establishments/loaded/')
      })
      deferred.resolve([])
    })

    it('should call `$.publish` the error event', function () {
      const deferred = $.Deferred()
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      spyOn($, 'publish')

      helper.init().then(function () {}, function () {
        expect($.publish).toHaveBeenCalledWith('/API/establishments/load/error/', {
          status: 'status',
          error: 'error'
        })
      })
      deferred.reject('status', 'error')
    })

    it('should set the internalCache', function () {
      const deferred = $.Deferred()
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      helper.init().then(function () {
        expect(helper.getLocationByCategory()).toEqual([{
          id: 1,
          name: 'HMP Altcourse',
          category: 'prison',
          postcode: 'L9 7LH'
        }])
      })
      deferred.resolve([{
        id: 1,
        name: 'HMP Altcourse',
        category: 'prison',
        postcode: 'L9 7LH'
      }])
    })
  })

  describe('...getLocationByCategory', function () {
    beforeEach(function () {
      $('body').append('<div id="expenses" data-feature-distance="true">here</div>')
    })
    afterEach(function () {
      $('#expenses').remove()
    })

    it('should return all the data with no params passed', function () {
      const deferred = $.Deferred()
      const fixtureData = [{
        id: 1,
        name: 'HMP One',
        category: 'hospital',
        postcode: 'L9 7LH'
      }, {
        id: 2,
        name: 'HMP Two',
        category: 'prison',
        postcode: 'L9 7LH'
      }, {
        id: 3,
        name: 'HMP Three',
        category: 'crown_court',
        postcode: 'L9 7LH'
      }]
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      helper.init().then(function () {
        expect(helper.getLocationByCategory()).toEqual(fixtureData)
      })
      deferred.resolve(fixtureData)
    })

    it('should filter the results', function () {
      const deferred = $.Deferred()
      const fixtureData = [{
        id: 1,
        name: 'HMP One',
        category: 'hospital',
        postcode: 'L9 7LH'
      }, {
        id: 2,
        name: 'HMP Two',
        category: 'prison',
        postcode: 'L9 7LH'
      }, {
        id: 3,
        name: 'HMP Three',
        category: 'crown_court',
        postcode: 'L9 7LH'
      }]

      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      helper.init().then(function () {
        expect(helper.getLocationByCategory('prison')).toEqual([fixtureData[2]])

        expect(helper.getLocationByCategory('crown_court')).toEqual([fixtureData[1]])
      })
      deferred.resolve(fixtureData)
    })
  })

  describe('...getAsOptions', function () {
    beforeEach(function () {
      $('body').append('<div id="expenses" data-feature-distance="true">here</div>')
    })
    afterEach(function () {
      $('#expenses').remove()
    })

    it('should filter the results', function () {
      const deferred = $.Deferred()
      const fixtureData = [{
        id: 1,
        name: 'HMP One',
        category: 'hospital',
        postcode: 'L9 7LH'
      }, {
        id: 2,
        name: 'HMP Two',
        category: 'prison',
        postcode: 'L9 7LH'
      }, {
        id: 3,
        name: 'HMP Three',
        category: 'crown_court',
        postcode: 'L9 7LH'
      }]
      spyOn(moj.Helpers.API._CORE, 'query').and.returnValue(deferred.promise())

      helper.init().then(function () {
        helper.getAsOptions('prison').then(function (el) {
          expect(el).toEqual(['<option value="">Please select</option>', '<option value="2" data-postcode="L9 7LH">HMP Two</option>'])
        })
        helper.getAsOptions('crown_court').then(function (el) {
          expect(el).toEqual(['<option value="">Please select</option>', '<option value="3" data-postcode="L9 7LH">HMP Three</option>'])
        })
      })
      deferred.resolve(fixtureData)
    })
  })
})
