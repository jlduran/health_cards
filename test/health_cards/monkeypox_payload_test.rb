# frozen_string_literal: true

require 'test_helper'

class MonkeypoxPayloadTest < ActiveSupport::TestCase
  setup do
    @bundle = FHIR::Bundle.new(load_json_fixture('example-monkeypox-immunization-bundle'))
    @card = HealthCards::MonkeypoxPayload.new(bundle: @bundle, issuer: 'http://example.org')
  end

  class MonkeypoxHealthCardSame < HealthCards::MonkeypoxPayload; end

  class MonkeypoxHealthCardChanged < HealthCards::MonkeypoxPayload
    fhir_version '4.0.2'
    additional_types 'https://smarthealth.cards#test'
  end

  test 'is of custom type' do
    assert @card.is_a?(HealthCards::MonkeypoxPayload)
  end

  test 'includes correct types' do
    assert_includes HealthCards::MonkeypoxPayload.types, 'https://smarthealth.cards#health-card'
    assert_includes HealthCards::MonkeypoxPayload.types, 'https://smarthealth.cards#monkeypox'
  end

  test 'includes required credential attributes in hash' do
    hash = @card.to_hash
    type = hash.dig(:vc, :type)

    assert_not_nil type
    assert_includes type, 'https://smarthealth.cards#health-card'
    assert_includes type, 'https://smarthealth.cards#monkeypox'

    fhir_version = hash.dig(:vc, :credentialSubject, :fhirVersion)

    assert_not_nil fhir_version
    assert_equal HealthCards::MonkeypoxPayload.fhir_version, fhir_version
  end

  test 'bundle creation' do
    @card = rails_issuer.issue_health_card(@bundle, type: HealthCards::MonkeypoxPayload)
    bundle = @card.bundle

    assert_equal 3, bundle.entry.size
    assert_equal 'collection', bundle.type

    patient = bundle.entry[0].resource

    assert_equal FHIR::Patient, patient.class
    assert_predicate patient, :valid?

    bundle.entry[1..3].map(&:resource).each do |imm|
      assert_equal FHIR::Immunization, imm.class
      # FHIR Validator thinks references are invalid so can't validate Immunization
    end
  end

  test 'valid bundle json' do
    assert_nothing_raised do
      assert_fhir(@card.bundle.to_json, type: FHIR::Bundle, validate: false)
    end
  end

  test 'supports multiple types' do
    assert HealthCards::MonkeypoxPayload.supports_type? [
      'https://smarthealth.cards#health-card', 'https://smarthealth.cards#monkeypox'
    ]
  end

  test 'minified patient entries' do
    bundle = @card.strip_fhir_bundle

    assert_equal 3, bundle.entry.size
    patient = bundle.entry[0].resource

    assert_equal 'Jane', patient.name.first.given.first
    assert_equal '1961-01-20', patient.birthDate
    assert_nil patient.gender
    assert_equal 'ghp-example', patient.identifier[0].value
  end

  test 'inheritance of attributes' do
    assert_equal HealthCards::MonkeypoxPayload.types, MonkeypoxHealthCardSame.types
    assert_equal HealthCards::MonkeypoxPayload.fhir_version, MonkeypoxHealthCardSame.fhir_version
    assert_equal 1, HealthCards::Payload.types.length
    assert_equal 2, HealthCards::MonkeypoxPayload.types.length
    assert_equal 3, MonkeypoxHealthCardChanged.types.length
    assert_equal HealthCards::MonkeypoxPayload.types.length + 1, MonkeypoxHealthCardChanged.types.length
    assert_includes MonkeypoxHealthCardChanged.types, 'https://smarthealth.cards#test'
    assert_equal '4.0.2', MonkeypoxHealthCardChanged.fhir_version
  end
end
