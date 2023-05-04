
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			/// A CResult_FixedPenaltyScorerDecodeErrorZ represents the result of a fallible operation,
			/// containing a crate::lightning::routing::scoring::FixedPenaltyScorer on success and a crate::lightning::ln::msgs::DecodeError on failure.
			/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
			public typealias Result_FixedPenaltyScorerDecodeErrorZ = Bindings.Result_FixedPenaltyScorerDecodeErrorZ

			extension Bindings {

				/// A CResult_FixedPenaltyScorerDecodeErrorZ represents the result of a fallible operation,
				/// containing a crate::lightning::routing::scoring::FixedPenaltyScorer on success and a crate::lightning::ln::msgs::DecodeError on failure.
				/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
				public class Result_FixedPenaltyScorerDecodeErrorZ: NativeTypeWrapper {

					
					public static var enableDeinitLogging = true
					public static var suspendFreedom = false
					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKCResult_FixedPenaltyScorerDecodeErrorZ?

					internal init(cType: LDKCResult_FixedPenaltyScorerDecodeErrorZ, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKCResult_FixedPenaltyScorerDecodeErrorZ, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}
		

					
					/// Creates a new CResult_FixedPenaltyScorerDecodeErrorZ in the success state.
					public class func initWithOk(o: FixedPenaltyScorer) -> Result_FixedPenaltyScorerDecodeErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_FixedPenaltyScorerDecodeErrorZ_ok(o.dynamicallyDangledClone().cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_FixedPenaltyScorerDecodeErrorZ(cType: nativeCallResult, instantiationContext: "Result_FixedPenaltyScorerDecodeErrorZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Creates a new CResult_FixedPenaltyScorerDecodeErrorZ in the error state.
					public class func initWithErr(e: DecodeError) -> Result_FixedPenaltyScorerDecodeErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_FixedPenaltyScorerDecodeErrorZ_err(e.danglingClone().cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_FixedPenaltyScorerDecodeErrorZ(cType: nativeCallResult, instantiationContext: "Result_FixedPenaltyScorerDecodeErrorZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Frees any resources used by the CResult_FixedPenaltyScorerDecodeErrorZ.
					internal func free() {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_FixedPenaltyScorerDecodeErrorZ_free(self.cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = nativeCallResult
						

						return returnValue
					}
		
					/// Creates a new CResult_FixedPenaltyScorerDecodeErrorZ which has the same data as `orig`
					/// but with all dynamically-allocated buffers duplicated in new buffers.
					internal func clone() -> Result_FixedPenaltyScorerDecodeErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = 
						withUnsafePointer(to: self.cType!) { (origPointer: UnsafePointer<LDKCResult_FixedPenaltyScorerDecodeErrorZ>) in
				CResult_FixedPenaltyScorerDecodeErrorZ_clone(origPointer)
						}
				

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_FixedPenaltyScorerDecodeErrorZ(cType: nativeCallResult, instantiationContext: "Result_FixedPenaltyScorerDecodeErrorZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		

					public func isOk() -> Bool {
						return self.cType?.result_ok == true
					}

					
					public func getError() -> DecodeError? {
						if self.cType?.result_ok == false {
							return DecodeError(cType: self.cType!.contents.err.pointee, instantiationContext: "Result_FixedPenaltyScorerDecodeErrorZ.swift::\(#function):\(#line)", anchor: self)
						}
						return nil
					}
					

					
					public func getValue() -> FixedPenaltyScorer? {
						if self.cType?.result_ok == true {
							return FixedPenaltyScorer(cType: self.cType!.contents.result.pointee, instantiationContext: "Result_FixedPenaltyScorerDecodeErrorZ.swift::\(#function):\(#line)", anchor: self)
						}
						return nil
					}
					

					internal func dangle(_ shouldDangle: Bool = true) -> Result_FixedPenaltyScorerDecodeErrorZ {
        				self.dangling = shouldDangle
						return self
					}

					
					internal func danglingClone() -> Result_FixedPenaltyScorerDecodeErrorZ {
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
								Bindings.print("Freeing Result_FixedPenaltyScorerDecodeErrorZ \(self.instanceNumber). (Origin: \(self.instantiationContext))")
							}
							
							self.free()
						} else if Self.enableDeinitLogging {
							Bindings.print("Not freeing Result_FixedPenaltyScorerDecodeErrorZ \(self.instanceNumber) due to dangle. (Origin: \(self.instantiationContext))")
						}
					}
			

				}

			}
		