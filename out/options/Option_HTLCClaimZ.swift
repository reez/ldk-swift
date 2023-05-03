
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			/// 
			internal typealias Option_HTLCClaimZ = Bindings.Option_HTLCClaimZ

			extension Bindings {

				/// An enum which can either contain a crate::lightning::ln::chan_utils::HTLCClaim or not
				internal class Option_HTLCClaimZ: NativeTypeWrapper {

					
					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKCOption_HTLCClaimZ?

					internal init(cType: LDKCOption_HTLCClaimZ, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKCOption_HTLCClaimZ, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}
		

					internal init(some: HTLCClaim?) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter

						if let some = some {
														
							self.cType = COption_HTLCClaimZ_some(some.getCValue())
						} else {
							self.cType = COption_HTLCClaimZ_none()
						}

						super.init(conflictAvoidingVariableName: 0, instantiationContext: "Option_HTLCClaimZ.swift::\(#function):\(#line)")
					}

					
					/// Frees any resources associated with the crate::lightning::ln::chan_utils::HTLCClaim, if we are in the Some state
					internal func free() {
						// native call variable prep
						

						// native method call
						let nativeCallResult = COption_HTLCClaimZ_free(self.cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = nativeCallResult
						

						return returnValue
					}
		

					public func getValue() -> HTLCClaim? {
						if self.cType!.tag == LDKCOption_HTLCClaimZ_None {
							return nil
						}
						if self.cType!.tag == LDKCOption_HTLCClaimZ_Some {
							return HTLCClaim(value: self.cType!.some)
						}
						assert(false, "invalid option enum value")
						return nil
					}

					internal func dangle(_ shouldDangle: Bool = true) -> Option_HTLCClaimZ {
        				self.dangling = shouldDangle
						return self
					}

					
					deinit {
						if Bindings.suspendFreedom {
							return
						}

						if !self.dangling {
							Bindings.print("Freeing Option_HTLCClaimZ \(self.instanceNumber).")
							
							self.free()
						} else {
							Bindings.print("Not freeing Option_HTLCClaimZ \(self.instanceNumber) due to dangle.")
						}
					}
			

				}

			}
		