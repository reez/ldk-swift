public class Result_TxCreationKeysErrorZ {

	private static var instanceCounter: UInt = 0
	internal let instanceNumber: UInt
	internal private(set) var dangling = false

    public internal(set) var cOpaqueStruct: LDKCResult_TxCreationKeysErrorZ?;

	/* DEFAULT_CONSTRUCTOR_START */

				public init() {
					Self.instanceCounter += 1
					self.instanceNumber = Self.instanceCounter
        			self.cOpaqueStruct = LDKCResult_TxCreationKeysErrorZ(contents: LDKCResult_TxCreationKeysErrorZPtr(), result_ok: true)
				}
			
    /* DEFAULT_CONSTRUCTOR_END */

    public init(pointer: LDKCResult_TxCreationKeysErrorZ){
    	Self.instanceCounter += 1
		self.instanceNumber = Self.instanceCounter
		self.cOpaqueStruct = pointer
	}

	public func isOk() -> Bool {
		return self.cOpaqueStruct?.result_ok == true
	}

    /* RESULT_METHODS_START */

			public func getError() -> LDKSecp256k1Error? {
				if self.cOpaqueStruct?.result_ok == false {
					return self.cOpaqueStruct!.contents.err.pointee
				}
				return nil
			}
			
			public func getValue() -> TxCreationKeys? {
				if self.cOpaqueStruct?.result_ok == true {
					return TxCreationKeys(pointer: self.cOpaqueStruct!.contents.result.pointee)
				}
				return nil
			}
			
    public class func ok(o: TxCreationKeys) -> Result_TxCreationKeysErrorZ {
    	
        return Result_TxCreationKeysErrorZ(pointer: CResult_TxCreationKeysErrorZ_ok(o.danglingClone().cOpaqueStruct!));
    }

    public class func err(e: LDKSecp256k1Error) -> Result_TxCreationKeysErrorZ {
    	
        return Result_TxCreationKeysErrorZ(pointer: CResult_TxCreationKeysErrorZ_err(e));
    }

    internal func free() -> Void {
    	
        return CResult_TxCreationKeysErrorZ_free(self.cOpaqueStruct!);
    }

					internal func dangle() -> Result_TxCreationKeysErrorZ {
        				self.dangling = true
						return self
					}
					
					deinit {
						if !self.dangling {
							self.free()
						}
					}
				

    public func clone() -> Result_TxCreationKeysErrorZ {
    	
        return Result_TxCreationKeysErrorZ(pointer: withUnsafePointer(to: self.cOpaqueStruct!) { (origPointer: UnsafePointer<LDKCResult_TxCreationKeysErrorZ>) in
CResult_TxCreationKeysErrorZ_clone(origPointer)
});
    }

					internal func danglingClone() -> Result_TxCreationKeysErrorZ {
        				var dangledClone = self.clone()
						dangledClone.dangling = true
						return dangledClone
					}
				

    /* RESULT_METHODS_END */

}
