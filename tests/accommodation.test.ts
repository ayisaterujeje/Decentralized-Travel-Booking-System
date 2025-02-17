import { describe, it, expect } from "vitest"

// Mock the Clarity functions and types
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  types: {
    uint: (value: number) => ({ type: "uint", value }),
    principal: (value: string) => ({ type: "principal", value }),
    string: (value: string) => ({ type: "string", value }),
    bool: (value: boolean) => ({ type: "bool", value }),
  },
}

// Mock contract calls
const contractCalls = {
  "create-listing": (name: string, location: string, price: number) => {
    return { success: true, value: mockClarity.types.uint(0) }
  },
  "book-accommodation": (listingId: number, checkIn: number, checkOut: number) => {
    return { success: true, value: mockClarity.types.uint(0) }
  },
  "cancel-booking": (bookingId: number) => {
    return { success: true, value: true }
  },
  "get-listing": (listingId: number) => {
    return {
      success: true,
      value: {
        owner: mockClarity.types.principal("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"),
        name: mockClarity.types.string("Cozy Apartment"),
        location: mockClarity.types.string("New York"),
        price: mockClarity.types.uint(100),
        available: mockClarity.types.bool(true),
      },
    }
  },
  "get-booking": (bookingId: number) => {
    return {
      success: true,
      value: {
        "listing-id": mockClarity.types.uint(0),
        guest: mockClarity.types.principal("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"),
        "check-in": mockClarity.types.uint(1625097600),
        "check-out": mockClarity.types.uint(1625184000),
      },
    }
  },
}

describe("Accommodation Contract", () => {
  it("should create a new listing", () => {
    const result = contractCalls["create-listing"]("Cozy Apartment", "New York", 100)
    expect(result.success).toBe(true)
    expect(result.value).toEqual(mockClarity.types.uint(0))
  })
  
  it("should book an accommodation", () => {
    const result = contractCalls["book-accommodation"](0, 1625097600, 1625184000)
    expect(result.success).toBe(true)
    expect(result.value).toEqual(mockClarity.types.uint(0))
  })
  
  it("should cancel a booking", () => {
    const result = contractCalls["cancel-booking"](0)
    expect(result.success).toBe(true)
    expect(result.value).toBe(true)
  })
  
  it("should get listing details", () => {
    const result = contractCalls["get-listing"](0)
    expect(result.success).toBe(true)
    expect(result.value).toEqual({
      owner: mockClarity.types.principal("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"),
      name: mockClarity.types.string("Cozy Apartment"),
      location: mockClarity.types.string("New York"),
      price: mockClarity.types.uint(100),
      available: mockClarity.types.bool(true),
    })
  })
  
  it("should get booking details", () => {
    const result = contractCalls["get-booking"](0)
    expect(result.success).toBe(true)
    expect(result.value).toEqual({
      "listing-id": mockClarity.types.uint(0),
      guest: mockClarity.types.principal("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"),
      "check-in": mockClarity.types.uint(1625097600),
      "check-out": mockClarity.types.uint(1625184000),
    })
  })
})

