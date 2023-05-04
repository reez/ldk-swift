
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			import Foundation // necessary for Data for Strings

			/// Integer in the range `0..32`
			internal typealias U5 = Bindings.U5

			extension Bindings {

				/// Integer in the range `0..32`
				internal class U5: NativeTypeWrapper {

					

					
					public static var enableDeinitLogging = true
					public static var suspendFreedom = false
					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKU5?

					internal init(cType: LDKU5, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKU5, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}
		

					internal init(value: UInt8, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter

						self.cType = LDKU5(_0: value)

						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					

					public func getValue() -> UInt8 {
						return self.cType!._0
					}

					internal func dangle(_ shouldDangle: Bool = true) -> U5 {
        				self.dangling = shouldDangle
						return self
					}

										

				}

			}
		