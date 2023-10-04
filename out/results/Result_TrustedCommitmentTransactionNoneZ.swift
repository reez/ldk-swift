
			#if SWIFT_PACKAGE
			import LDKHeaders
			#endif

			/// A CResult_TrustedCommitmentTransactionNoneZ represents the result of a fallible operation,
			/// containing a crate::lightning::ln::chan_utils::TrustedCommitmentTransaction on success and a () on failure.
			/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
			public typealias Result_TrustedCommitmentTransactionNoneZ = Bindings.Result_TrustedCommitmentTransactionNoneZ

			extension Bindings {

				/// A CResult_TrustedCommitmentTransactionNoneZ represents the result of a fallible operation,
				/// containing a crate::lightning::ln::chan_utils::TrustedCommitmentTransaction on success and a () on failure.
				/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
				public class Result_TrustedCommitmentTransactionNoneZ: NativeTypeWrapper {

					
					/// Set to false to suppress an individual type's deinit log statements.
					/// Only applicable when log threshold is set to `.Debug`.
					public static var enableDeinitLogging = true

					/// Set to true to suspend the freeing of this type's associated Rust memory.
					/// Should only ever be used for debugging purposes, and will likely be
					/// deprecated soon.
					public static var suspendFreedom = false

					private static var instanceCounter: UInt = 0
					internal let instanceNumber: UInt

					internal var cType: LDKCResult_TrustedCommitmentTransactionNoneZ?

					internal init(cType: LDKCResult_TrustedCommitmentTransactionNoneZ, instantiationContext: String) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
					}

					internal init(cType: LDKCResult_TrustedCommitmentTransactionNoneZ, instantiationContext: String, anchor: NativeTypeWrapper) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = true
						try! self.addAnchor(anchor: anchor)
					}

					internal init(cType: LDKCResult_TrustedCommitmentTransactionNoneZ, instantiationContext: String, anchor: NativeTypeWrapper, dangle: Bool = false) {
						Self.instanceCounter += 1
						self.instanceNumber = Self.instanceCounter
						self.cType = cType
						
						super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
						self.dangling = dangle
						try! self.addAnchor(anchor: anchor)
					}
		

					
					/// Creates a new CResult_TrustedCommitmentTransactionNoneZ in the success state.
					@available(*, deprecated, message: "This method passes the following non-cloneable, but freeable objects by value: `o`.")
					public class func initWithOk(o: TrustedCommitmentTransaction) -> Result_TrustedCommitmentTransactionNoneZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_TrustedCommitmentTransactionNoneZ_ok(o.dangle().cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_TrustedCommitmentTransactionNoneZ(cType: nativeCallResult, instantiationContext: "Result_TrustedCommitmentTransactionNoneZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Creates a new CResult_TrustedCommitmentTransactionNoneZ in the error state.
					public class func initWithErr() -> Result_TrustedCommitmentTransactionNoneZ {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_TrustedCommitmentTransactionNoneZ_err()

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = Result_TrustedCommitmentTransactionNoneZ(cType: nativeCallResult, instantiationContext: "Result_TrustedCommitmentTransactionNoneZ.swift::\(#function):\(#line)")
						

						return returnValue
					}
		
					/// Frees any resources used by the CResult_TrustedCommitmentTransactionNoneZ.
					internal func free() {
						// native call variable prep
						

						// native method call
						let nativeCallResult = CResult_TrustedCommitmentTransactionNoneZ_free(self.cType!)

						// cleanup
						

						
						// return value (do some wrapping)
						let returnValue = nativeCallResult
						

						return returnValue
					}
		

					public func isOk() -> Bool {
						return self.cType?.result_ok == true
					}

					/*
					public func getError() -> Void? {
						if self.cType?.result_ok == false {
							return self.cType!.contents.err.pointee
						}
						return nil
					}
					*/

					
					public func getValue() -> TrustedCommitmentTransaction? {
						if self.cType?.result_ok == true {
							return TrustedCommitmentTransaction(cType: self.cType!.contents.result.pointee, instantiationContext: "Result_TrustedCommitmentTransactionNoneZ.swift::\(#function):\(#line)", anchor: self)
						}
						return nil
					}
					

					
					deinit {
						if Bindings.suspendFreedom || Self.suspendFreedom {
							return
						}

						if !self.dangling {
							if Self.enableDeinitLogging {
								Bindings.print("Freeing Result_TrustedCommitmentTransactionNoneZ \(self.instanceNumber). (Origin: \(self.instantiationContext))")
							}
							
							self.free()
						} else if Self.enableDeinitLogging {
							Bindings.print("Not freeing Result_TrustedCommitmentTransactionNoneZ \(self.instanceNumber) due to dangle. (Origin: \(self.instantiationContext))")
						}
					}
			

				}

			}
		