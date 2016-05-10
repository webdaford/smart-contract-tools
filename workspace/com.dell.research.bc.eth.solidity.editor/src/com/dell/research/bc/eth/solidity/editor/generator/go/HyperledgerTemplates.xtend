/*******************************************************************************
 * Copyright (c) 2016 Keoja LLC and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *     Daniel Ford, Keoja LLC
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.generator.go

import com.dell.research.bc.eth.solidity.editor.solidity.DefinitionBody
import org.eclipse.emf.common.util.EList
import com.dell.research.bc.eth.solidity.editor.solidity.FunctionDefinition
import com.dell.research.bc.eth.solidity.editor.solidity.ExpressionStatement
import com.dell.research.bc.eth.solidity.editor.solidity.Assignment
import com.dell.research.bc.eth.solidity.editor.solidity.ReturnStatement
import com.dell.research.bc.eth.solidity.editor.solidity.QualifiedIdentifier

class HyperledgerTemplates {
	static def doFileHeader() {
		'''
			package main
			import (
					"errors"
					"fmt"
							
					"github.com/hyperledger/fabric/core/chaincode/shim"
			)
			
			SimpleChaincode example simple Chaincode implementation
			 			type SimpleChaincode struct {
			}
			
			// =======================
			// Main
			// =======================
			func main() {
			     err := shim.Start(new(SimpleChaincode))
				 if err != nil {
				 fmt.Printf("Error starting Simple chaincode: %s", err)
			}
			
		'''
	} // doFileHeader

	static def doFuncInit(DefinitionBody body) {
		'''
			func (t *SimpleChaincode) Init(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
				
			}
			
		'''
	} // doFuncInit

	// «doInvokeClause(functions.get(0))»
	static def doFuncInvoke(EList<FunctionDefinition> functions) {
		'''
			// ============================================================================================================================
			// Invoke - Our entry point
			// ============================================================================================================================
			func (t *SimpleChaincode) Invoke(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
				// Handle different functions
				if function == "init" {
					return t.Init(stub, "init", args)
				} 
				«FOR f : functions BEFORE 'else '»
					«doInvokeClause(f)»
				«ENDFOR»
				fmt.Println("invoke did not find func: " + function)
				
				return nil, errors.New("Received unknown function invocation")
			}
				
		'''
	} // doFuncInvoke

	static def doFuncQuery(EList<FunctionDefinition> functions) {
		'''
			// ============================================================================================================================
			// Query - Our entry point for Queries
			// ============================================================================================================================
			func (t *SimpleChaincode) Query(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
				// Handle different functions
				«FOR f : functions»
					«doInvokeClause(f)»
				«ENDFOR»
				fmt.Println("query did not find func: " + function)
				
				return nil, errors.New("Received unknown function query")
			}
			
		'''
	} // doFuncQuery

	/**
	 * Return a go "if" statement testing for the function name and invoking it if found.
	 */
	static def doInvokeClause(FunctionDefinition function) {
		'''
			if function == "«function.name»" {
			  return t.«function.name»(stub, args)
			}
		'''
	} // doInvokeClause

	static def doFunction(FunctionDefinition function) {
		'''
			func (t *SimpleChaincode) «function.name»(stub *shim.ChaincodeStub, args []string) ([]byte, error) {
				«FOR stmt : function.block.statements»
					«IF stmt instanceof ExpressionStatement»
						write("«((stmt.expression as Assignment).left as QualifiedIdentifier).identifier »", «Utilities.extractValue((stmt.expression as Assignment).expression)»)
					«ELSEIF stmt instanceof ReturnStatement»
						read("«Utilities.extractValue((stmt as ReturnStatement).expression)»")
					«ELSE»
						stmt.toString
					«ENDIF»
					
				«ENDFOR»
			}
		'''
	} // doFunction

	static def doWriteFunc() {
		'''
			// ============================================================================================================================
			// write - invoke function to write key/value pair
			// ============================================================================================================================
			func (t *SimpleChaincode) write(stub *shim.ChaincodeStub, args []string) ([]byte, error) {
				var name, value string
				var err error
				fmt.Println("running write()")
			
				if len(args) != 2 {
					return nil, errors.New("Incorrect number of arguments. Expecting 2. name of the variable and value to set")
				}
			
				name = args[0]                            //rename for funsies
				value = args[1]
				err = stub.PutState(name, []byte(value))  //write the variable into the chaincode state
				if err != nil {
					return nil, err
				}
				return nil, nil
			}
		'''
	}

	static def doReadFunc() {
		'''
			// ============================================================================================================================
			// read - query function to read key/value pair
			// ============================================================================================================================
			func (t *SimpleChaincode) read(stub *shim.ChaincodeStub, args []string) ([]byte, error) {
				var name, jsonResp string
				var err error
			
				if len(args) != 1 {
					return nil, errors.New("Incorrect number of arguments. Expecting name of the var to query")
				}
			
				name = args[0]
				valAsbytes, err := stub.GetState(name)
				if err != nil {
					jsonResp = "{\"Error\":\"Failed to get state for " + name + "\"}"
					return nil, errors.New(jsonResp)
				}
			
				return valAsbytes, nil
			}
			
		'''
	}
} // HyperledgerUtiiities
