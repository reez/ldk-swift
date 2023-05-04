
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			/// A tuple of 2 elements. See the individual fields for the types contained.
			internal typealias Tuple_PublicKeyCOption_NetAddressZZ = Bindings.Tuple_PublicKeyCOption_NetAddressZZ

			extension Bindings {

				/// A tuple of 2 elements. See the individual fields for the types contained.
				internal class Tuple_PublicKeyCOption_NetAddressZZ: NativeTypeWrapper {

					
					public static var enableDeinitLogging = true
					public static var suspendFreedom = false
					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKC2Tuple_PublicKeyCOption_NetAddressZZ?

					internal init(cType: LDKC2Tuple_PublicKeyCOption_NetAddressZZ, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKC2Tuple_PublicKeyCOption_NetAddressZZ, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}
		

					internal convenience init(tuple: ([UInt8], NetAddress?), instantiationContext: String) {
						self.init(a: tuple.0, b: tuple.1, instantiationContext: instantiationContext)
					}

					
					/// Creates a new tuple which has the same data as `orig`
					/// but with all dynamically-allocated buffers duplicated in new buffers.
					internal func clone() -> Tuple_PublicKeyCOption_NetAddressZZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = 
						withUnsafePointer(to: self.cType!) { (origPointer: UnsafePointer<LDKC2Tuple_PublicKeyCOption_NetAddressZZ>) in
				C2Tuple_PublicKeyCOption_NetAddressZZ_clone(origPointer)
						}
				

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Tuple_PublicKeyCOption_NetAddressZZ(cType: nativeCallResult, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Creates a new C2Tuple_PublicKeyCOption_NetAddressZZ from the contained elements.
					public init(a: [UInt8], b: NetAddress?, instantiationContext: String) {
						// native call variable prep
						
						let aPrimitiveWrapper = PublicKey(value: a, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)")
				
						let bOption = Option_NetAddressZ(some: b, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)").danglingClone()
				

						// native method call
						let nativeCallResult = C2Tuple_PublicKeyCOption_NetAddressZZ_new(aPrimitiveWrapper.cType!, bOption.cType!)

						// cleanup
						
						// for elided types, we need this
						aPrimitiveWrapper.noOpRetain()
				

						/*
						// return value (do some wrapping)
						let returnValue = Tuple_PublicKeyCOption_NetAddressZZ(cType: nativeCallResult, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)")
						*/

						
				self.cType = nativeCallResult

				Self.instanceCounter += 1
				self.instanceNumber = Self.instanceCounter
				super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
				
			
					}
		
					/// Frees any resources used by the C2Tuple_PublicKeyCOption_NetAddressZZ.
					internal func free() {
						// native call variable prep
						

						// native method call
						let nativeCallResult = C2Tuple_PublicKeyCOption_NetAddressZZ_free(self.cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = nativeCallResult
						

						return returnValue
					}
		

					public func getValue() -> ([UInt8], NetAddress?) {
						return (self.getA(), self.getB())
					}

					
					/// The element at position 0
					public func getA() -> [UInt8] {
						// return value (do some wrapping)
						let returnValue = PublicKey(cType: self.cType!.a, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)", anchor: self).dangle().getValue()

						return returnValue;
					}
		
					/// The element at position 1
					public func getB() -> NetAddress? {
						// return value (do some wrapping)
						let returnValue = Option_NetAddressZ(cType: self.cType!.b, instantiationContext: "Tuple_PublicKeyCOption_NetAddressZZ.swift::\(#function):\(#line)", anchor: self).dangle().getValue()

						return returnValue;
					}
		

					internal func dangle(_ shouldDangle: Bool = true) -> Tuple_PublicKeyCOption_NetAddressZZ {
						self.dangling = shouldDangle
						return self
					}

					
					internal func danglingClone() -> Tuple_PublicKeyCOption_NetAddressZZ {
						let dangledClone = self.clone()
						dangledClone.dangling = true
						return dangledClone
					}
			
					deinit {
						if Bindings.suspendFreedom || Self.suspendFreedom {
							return
						}

						if !self.dangling {
							if Self.enableDeinitLogging {
								Bindings.print("Freeing Tuple_PublicKeyCOption_NetAddressZZ \(self.instanceNumber). (Origin: \(self.instantiationContext))")
							}
							
							self.free()
						} else if Self.enableDeinitLogging {
							Bindings.print("Not freeing Tuple_PublicKeyCOption_NetAddressZZ \(self.instanceNumber) due to dangle. (Origin: \(self.instantiationContext))")
						}
					}
			

				}
			}
		