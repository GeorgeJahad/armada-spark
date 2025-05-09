/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.spark.deploy.armada


import org.apache.spark.SparkConf
import org.scalatest.funsuite.AnyFunSuite
import Config._
import org.apache.spark.deploy.armada.K8sLabelValidator.{isValidKey, isValidValue}
import org.scalatest.prop.TableDrivenPropertyChecks
import org.scalatest.matchers.should.Matchers

class ConfigSuite
 extends AnyFunSuite
   with TableDrivenPropertyChecks
   with Matchers {
  test("testClusterSelectorsValidator") {
    val testCases = Table(
      // columns
      ("testSelectors", "expectedValid", "name"),
      // rows
      // Valid cases
      ("", true, "empty case"),
      ("a=1", true, "One character long name and value"),
      ("armada-spark=true", true, "One valid selector"),
      ("armada-spark=true,spark-cluster-name=001", true, "Two valid selectors"),
      ("armada-spark=false,name=spark-cluster-001,a=1,b=2,c=3", true, "Several valid selectors"),
      ("a" * 63 + "=" + "b" * 63, true, "Selector name & value length limit of 63"),
      ("a" * 30 + "-._" + "b" * 30 + "=b", true, "Selector name length limit of 63 with valid non-alphanumeric chars"),
      // Invalid cases
      ("a", false, "key but no value"),
      ("a=", false, "key & = but no value"),
      ("=b", false, "value & = but no key"),
      ("=", false, "just = and no key or value"),
      ("_armada=a", false, "Selector labels must start with an alphanumeric character."),
      ("armada_=b", false, "Selector labels must end with an alphanumeric character."),
      ("armada=_armada", false, "Selector values must start with an alphanumeric character."),
      ("armada=armada_", false, "Selector values must end with an alphanumeric character."),
      ("#@armada-spark=true,spark-cluster-name=spark-cluster-001", false, "Illegal characters: # @"),
      ("armada-spark=false,a==2", false, "Double equal sign"),
      ("armada-spark=false,a=b=2", false, "Two equal signs in label"),
      ("a" * 64 + "=b", false, "Selector names must be 63 characters or less"),
      ("armada=" + ("b" * 64), false, "Selector values must be 63 characters or less"),
    )

    forAll(testCases) { (testSelectors, expectedValid, name) =>
      withClue(name) {
        assert(Config.selectorsValidator(testSelectors) == expectedValid)
      }
    }
  }

  test("defaultClusterSelectors") {
    val conf = new SparkConf(true)
    assert(conf.get(ARMADA_CLUSTER_SELECTORS) == DEFAULT_CLUSTER_SELECTORS)
  }

  test("commaSeparatedLabelsToMap") {
    val testCases = Table(
      // columns
      ("labels",      "expected"),
      // rows
      ("",            Map.empty[String, String]),
      ("a=1",         Map("a" -> "1")),
      ("a=1,b=2",     Map("a" -> "1", "b" -> "2")),
      ("a=1,b=2,c=3", Map("a" -> "1", "b" -> "2", "c" -> "3")),
      ("a=1,,b=2,c=3", Map("a" -> "1", "b" -> "2", "c" -> "3")),
      (" a=1,b= 2, c = 3 ", Map("a" -> "1", "b" -> "2", "c" -> "3"))
    )

    forAll(testCases) { (labels , expected) =>
      commaSeparatedLabelsToMap(labels) shouldEqual expected
    }
  }

  test("K8sLabelValidator.isValidKey") {
    val cases = Table(
      ("key",                              "valid"),
      ("",                                 false),
      ("app",                              true),
      ("my-domain.io/app",                 true),
      ("example.com/label-name",           true),
      ("example_1.com/label-name",         true),
      ("a.b/a.s",                          true),
      ("a" * 254 + "/label-name",          false),
      ("_invalid",                         false),
      ("invalid-",                         false),
      ("/no-prefix-name",                  false),
      ("toolong" * 50,                     false),
      (null.asInstanceOf[String],          false)
    )

    forAll(cases) { (key, valid) =>
      withClue(s"isValidKey('$key'): ") {
        isValidKey(key) shouldBe valid
      }
    }
  }

  test("K8sLabelValidator.isValidValue") {
    val cases = Table(
      ("value",                "valid"),
      ("",                     true),
      ("frontend",             true),
      ("a",                    true),
      ("invalid value",        false),
      ("-leading",             false),
      ("trailing-",            false),
      ("a" * 63,               true),
      ("a" * 64,               false),
      (null.asInstanceOf[String], false)
    )

    forAll(cases) { (value, valid) =>
      withClue(s"isValidValue('$value'): ") {
        isValidValue(value) shouldBe valid
      }
    }
  }
}
