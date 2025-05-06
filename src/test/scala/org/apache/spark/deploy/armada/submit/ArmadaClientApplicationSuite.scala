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

package org.apache.spark.deploy.armada.submit

import k8s.io.api.core.v1.generated.VolumeMount
import org.apache.spark.SparkConf
import org.scalatest.BeforeAndAfter
import org.scalatest.funsuite.AnyFunSuite
import org.apache.spark.deploy.armada.Constants.DRIVER_PORT


class ArmadaClientApplicationSuite extends AnyFunSuite with BeforeAndAfter {
  val sparkConf = new SparkConf(false)
  val imageName = "imageName"
  val sparkMaster = "localhost"
  val className = "testClass"
  val driverServiceName = "driverService"
  val bindAddress = "$(SPARK_DRIVER_BIND_ADDRESS)"
  before {
    sparkConf.set("spark.armada.container.image", imageName)
    sparkConf.set("spark.master", sparkMaster)
  }
  test("Test get driver container default values") {
    val valueMap = Map(
      "limitMem" -> "1Gi",
      "limitStorage" -> "512Mi",
      "limitCPU" -> "1",
      "requestMem" -> "1Gi",
      "requestStorage" -> "512Mi",
      "requestCPU" -> "1")

    val aca = new ArmadaClientApplication()
    val container = aca.getDriverContainer(driverServiceName,
      ClientArguments.fromCommandLineArgs(Array("--main-class", className)), sparkConf, Seq(new VolumeMount))

    val driverArgsString = container.args.mkString("\n")
    assert(driverArgsString == getDriverArgs(valueMap))

    val driverPortString = container.ports.head.toProtoString
    assert(driverPortString == getDriverPort(valueMap))

    val driverEnvString = container.env.map(_.toProtoString).mkString
    assert(driverEnvString == getDriverEnv(valueMap))

    val driverResourcesString = container.resources.get.toProtoString
    assert(driverResourcesString == getResources(valueMap))
  }

  test("Test get driver container non-default values") {
    val valueMap = Map(
      "limitMem" -> "1Gi",
      "limitStorage" -> "512Mi",
      "limitCPU" -> "1",
      "requestMem" -> "1Gi",
      "requestStorage" -> "512Mi",
      "requestCPU" -> "1")


    val aca = new ArmadaClientApplication()
    val container = aca.getDriverContainer(driverServiceName,
      ClientArguments.fromCommandLineArgs(Array("--main-class", className)), sparkConf, Seq(new VolumeMount))

    val driverResourcesString = container.resources.get.toProtoString
    assert(driverResourcesString == getResources(valueMap))
  }

  private def getDriverArgs(valueMap: Map[String, String]) = {
    s"""|driver
        |--verbose
        |--class
        |$className
        |--master
        |$sparkMaster
        |--conf
        |spark.driver.port=$DRIVER_PORT
        |--conf
        |spark.armada.container.image=$imageName
        |--conf
        |spark.driver.host=$bindAddress
        |--conf
        |spark.master=$sparkMaster
        |--conf
        |spark.armada.container.image=$imageName""".stripMargin
  }

  private def getDriverPort(valueMap: Map[String, String]) = {
    s"""|name: "armada-spark-driver-port"
        |hostPort: 0
        |containerPort: $DRIVER_PORT
        |""".stripMargin
  }

  private def getDriverEnv(valueMap: Map[String, String]) = {
    s"""|name: "SPARK_DRIVER_BIND_ADDRESS"
        |valueFrom {
        |  fieldRef {
        |    apiVersion: "v1"
        |    fieldPath: "status.podIP"
        |  }
        |}
        |name: "SPARK_CONF_DIR"
        |value: "/opt/spark/conf"
        |name: "EXTERNAL_CLUSTER_SUPPORT_ENABLED"
        |value: "true"
        |name: "ARMADA_SPARK_DRIVER_SERVICE_NAME"
        |value: "$driverServiceName"
        |""".stripMargin

  }
  private def getResources(valueMap: Map[String, String]) = {
    s"""|limits {
        |  key: "memory"
        |  value {
        |    string: "${valueMap("limitMem")}"
        |  }
        |}
        |limits {
        |  key: "ephemeral-storage"
        |  value {
        |    string: "${valueMap("limitStorage")}"
        |  }
        |}
        |limits {
        |  key: "cpu"
        |  value {
        |    string: "${valueMap("limitCPU")}"
        |  }
        |}
        |requests {
        |  key: "memory"
        |  value {
        |    string: "${valueMap("requestMem")}"
        |  }
        |}
        |requests {
        |  key: "ephemeral-storage"
        |  value {
        |    string: "${valueMap("requestStorage")}"
        |  }
        |}
        |requests {
        |  key: "cpu"
        |  value {
        |    string: "${valueMap("requestCPU")}"
        |  }
        |}
        |""".stripMargin
  }

  test("Test get executor container") {
    val executorID = 0
    val expectedString = {
    s"""|name: "spark-executor-$executorID"
        |image: "$imageName"
        |command: "/opt/entrypoint.sh"
        |args: "executor"
        |env {
        |  name: "SPARK_EXECUTOR_ID"
        |  value: "$executorID"
        |}
        |env {
        |  name: "SPARK_RESOURCE_PROFILE_ID"
        |  value: "0"
        |}
        |env {
        |  name: "SPARK_EXECUTOR_POD_NAME"
        |  valueFrom {
        |    fieldRef {
        |      apiVersion: "v1"
        |      fieldPath: "metadata.name"
        |    }
        |  }
        |}
        |env {
        |  name: "SPARK_APPLICATION_ID"
        |  value: "armada-spark-app-id"
        |}
        |env {
        |  name: "SPARK_EXECUTOR_CORES"
        |  value: "1"
        |}
        |env {
        |  name: "SPARK_EXECUTOR_MEMORY"
        |  value: "1g"
        |}
        |env {
        |  name: "SPARK_DRIVER_URL"
        |  value: "spark://CoarseGrainedScheduler@driverService:7078"
        |}
        |env {
        |  name: "SPARK_EXECUTOR_POD_IP"
        |  valueFrom {
        |    fieldRef {
        |      apiVersion: "v1"
        |      fieldPath: "status.podIP"
        |    }
        |  }
        |}
        |env {
        |  name: "ARMADA_SPARK_GANG_NODE_UNIFORMITY_LABEL"
        |  value: "armada-spark"
        |}
        |env {
        |  name: "SPARK_JAVA_OPT_0"
        |  value: "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
        |}
        |resources {
        |  limits {
        |    key: "memory"
        |    value {
        |      string: "1Gi"
        |    }
        |  }
        |  limits {
        |    key: "ephemeral-storage"
        |    value {
        |      string: "512Mi"
        |    }
        |  }
        |  limits {
        |    key: "cpu"
        |    value {
        |      string: "1"
        |    }
        |  }
        |  requests {
        |    key: "memory"
        |    value {
        |      string: "1Gi"
        |    }
        |  }
        |  requests {
        |    key: "ephemeral-storage"
        |    value {
        |      string: "512Mi"
        |    }
        |  }
        |  requests {
        |    key: "cpu"
        |    value {
        |      string: "1"
        |    }
        |  }
        |}
        |imagePullPolicy: "IfNotPresent"
        |""".stripMargin
    }
    val aca = new ArmadaClientApplication()
    val container = aca.getExecutorContainer(executorID, driverServiceName, sparkConf)
    val pstring = container.toProtoString
    assert(pstring == expectedString)
  }

}