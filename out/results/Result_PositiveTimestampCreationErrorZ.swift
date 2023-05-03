
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			/// A CResult_PositiveTimestampCreationErrorZ represents the result of a fallible operation,
			/// containing a crate::lightning_invoice::PositiveTimestamp on success and a crate::lightning_invoice::CreationError on failure.
			/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
			public typealias Result_PositiveTimestampCreationErrorZ = Bindings.Result_PositiveTimestampCreationErrorZ

			extension Bindings {

				/// A CResult_PositiveTimestampCreationErrorZ represents the result of a fallible operation,
				/// containing a crate::lightning_invoice::PositiveTimestamp on success and a crate::lightning_invoice::CreationError on failure.
				/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
				public class Result_PositiveTimestampCreationErrorZ: NativeTypeWrapper {

					
					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKCResult_PositiveTimestampCreationErrorZ?

					internal init(cType: LDKCResult_PositiveTimestampCreationErrorZ, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKCResult_PositiveTimestampCreationErrorZ, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}
		

					
					/// Creates a new CResult_PositiveTimestampCreationErrorZ in the success state.
					public class func initWithOk(o: PositiveTimestamp) -> Result_PositiveTimestampCreationErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_PositiveTimestampCreationErrorZ_ok(o.dynamicallyDangledClone().cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_PositiveTimestampCreationErrorZ(cType: nativeCallResult, instantiationContext: "#{swift_class_name}::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Creates a new CResult_PositiveTimestampCreationErrorZ in the error state.
					public class func initWithErr(e: CreationError) -> Result_PositiveTimestampCreationErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_PositiveTimestampCreationErrorZ_err(e.getCValue())

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_PositiveTimestampCreationErrorZ(cType: nativeCallResult, instantiationContext: "#{swift_class_name}::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Frees any resources used by the CResult_PositiveTimestampCreationErrorZ.
					internal func free() {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_PositiveTimestampCreationErrorZ_free(self.cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = nativeCallResult
						

						return returnValue
					}
		
					/// Creates a new CResult_PositiveTimestampCreationErrorZ which has the same data as `orig`
					/// but with all dynamically-allocated buffers duplicated in new buffers.
					internal func clone() -> Result_PositiveTimestampCreationErrorZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = 
						withUnsafePointer(to: self.cType!) { (origPointer: UnsafePointer<LDKCResult_PositiveTimestampCreationErrorZ>) in
				CResult_PositiveTimestampCreationErrorZ_clone(origPointer)
						}
				

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_PositiveTimestampCreationErrorZ(cType: nativeCallResult, instantiationContext: "#{swift_class_name}::\(#function):\(#line)")
						

						return returnValue
					}
		

					public func isOk() -> Bool {
						return self.cType?.result_ok == true
					}

					
					public func getError() -> CreationError? {
						if self.cType?.result_ok == false {
							return CreationError(value: self.cType!.contents.err.pointee)
						}
						return nil
					}
					

					
					public func getValue() -> PositiveTimestamp? {
						if self.cType?.result_ok == true {
							return PositiveTimestamp(cType: self.cType!.contents.result.pointee, instantiationContext: "#{swift_class_name}::\(#function):\(#line)", anchor: self)
						}
						return nil
					}
					

					internal func dangle(_ shouldDangle: Bool = true) -> Result_PositiveTimestampCreationErrorZ {
        				self.dangling = shouldDangle
						return self
					}

					
					internal func danglingClone() -> Result_PositiveTimestampCreationErrorZ {
						let dangledClone = self.clone()
						dangledClone.dangling = true
						return dangledClone
					}
			
					deinit {
						if Bindings.suspendFreedom {
							return
						}

						if !self.dangling {
							Bindings.print("Freeing Result_PositiveTimestampCreationErrorZ \(self.instanceNumber).")
							
							self.free()
						} else {
							Bindings.print("Not freeing Result_PositiveTimestampCreationErrorZ \(self.instanceNumber) due to dangle.")
						}
					}
			

				}

			}
		