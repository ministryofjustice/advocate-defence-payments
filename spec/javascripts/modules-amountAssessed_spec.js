describe('Modules.AmountAssessedBlock.js', function () {
  const domFixture = $('<div class="main" />')
  const view = [
    '<div class="fx-assesment-hook">',
    '  <div class="js-cw-claim-assessment" id="claim-status" style="display: block;">',
    '    <h3 class="govuk-heading-m">',
    '      Assessment summary',
    '    </h3>',
    '  </div>',
    '  <div class="js-cw-claim-action">',
    '      <input type="radio" value="part_authorised" name="claim[state]" id="claim_state_part_authorised" />',
    '      <input type="radio" value="authorised" name="claim[state]" id="claim_state_authorised" />',
    '      <input type="radio" value="refused" name="claim[state]" id="claim_state_refused" />',
    '      <input type="radio" value="rejected" name="claim[state]" id="claim_state_rejected" />',
    '  </div>',
    '  <div class="js-cw-claim-rejection-reasons" style="display: none;">',
    '    <input type="radio" value="wrong_case_no" name="[state_reason]" id="_state_reason_wrong_case_no">',
    '    <input type="radio" value="other" name="[state_reason]" id="_state_reason_other">',
    '    <fieldset class="js-reject-reason-text">',
    '      <div>',
    '        <input class="form-control" type="text" name="claim[reason_text]" id="claim_reason_text">',
    '      </div>',
    '    </fieldset>',
    '  </div>',
    '</div>'
  ].join('')

  beforeEach(function () {
    domFixture.append($(view))
    $('body').append(domFixture)

    // reset to default state
    moj.Modules.AmountAssessed.init()
  })

  afterEach(function () {
    domFixture.empty()
  })

  describe('Defaults', function () {
    it('should have `this.config` defined', function () {
      const block = moj.Modules.AmountAssessed.blocks[0]
      expect(block.config).toEqual({
        hook: '.fx-assesment-hook',
        form: '.js-cw-claim-assessment',
        actions: '.js-cw-claim-action',
        reasons: '.js-cw-claim-rejection-reasons',
        refuseReasons: '.js-cw-claim-refuse-reasons',
        otherinput: '.js-reject-reason-text',
        otherRefuseInput: '.js-refuse-reason-text',
        otherCheckbox: '#state_reason_other',
        otherRefuseCheckbox: '#state_reason_other_refuse',
        action: 'toggle'
      })
    })

    it('should have `this.states` defined', function () {
      const block = moj.Modules.AmountAssessed.blocks[0]
      expect(block.states).toEqual({
        rejected: {
          form: false,
          reasons: true,
          refuseReasons: false
        },
        refused: {
          form: false,
          reasons: false,
          refuseReasons: true
        },
        authorised: {
          form: true,
          reasons: false,
          refuseReasons: false
        },
        part_authorised: {
          form: true,
          reasons: false,
          refuseReasons: false
        }
      })
    })
  })

  describe('Methods..', function () {
    describe('...slider', function () {
      it('should call correct $.fn', function () {
        const block = moj.Modules.AmountAssessed.blocks[0]
        let x = false
        $.fn.addClass = function () {
          x = true
        }
        expect(x).toEqual(false)
        block.slider(false, $('<div />'))
        expect(x).toEqual(true)
      })
    })
  })
})

describe('Modules.AmountAssessed.js', function () {
  beforeEach(function () {
    // reset to default state
    moj.Modules.AmountAssessed.init()
  })

  afterEach(function () {})

  describe('Defaults', function () {
    it('should have a `blocks` array defined', function () {
      expect(moj.Modules.AmountAssessed.blocks).toEqual(jasmine.any(Array))
    })

    it('should call `moj.Modules.AmountAssessedBlock` on init', function () {
      spyOn(moj.Modules, 'AmountAssessedBlock')
      moj.Modules.AmountAssessed.init()
      expect(moj.Modules.AmountAssessedBlock).toHaveBeenCalled()
    })
  })
})
