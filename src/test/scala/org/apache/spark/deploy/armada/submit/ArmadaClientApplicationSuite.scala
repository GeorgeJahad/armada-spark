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

import java.nio.file.{Files, Path, StandardOpenOption}

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
  test("Test get driver container") {
    val expectedString =
    s"""|name: "spark-driver"
        |image: "$imageName"
        |command: "/opt/entrypoint.sh"
        |args: "driver"
        |args: "--verbose"
        |args: "--class"
        |args: "$className"
        |args: "--master"
        |args: "$sparkMaster"
        |args: "--conf"
        |args: "spark.driver.port=7078"
        |args: "--conf"
        |args: "spark.armada.container.image=$imageName"
        |args: "--conf"
        |args: "spark.driver.host=$bindAddress"
        |args: "--conf"
        |args: "spark.master=localhost"
        |args: "--conf"
        |args: "spark.armada.container.image=imageName"
        |ports {
        |  name: "as-driver-port"
        |  hostPort: 0
        |  containerPort: 7078
        |}
        |env {
        |  name: "SPARK_DRIVER_BIND_ADDRESS"
        |  valueFrom {
        |    fieldRef {
        |      apiVersion: "v1"
        |      fieldPath: "status.podIP"
        |    }
        |  }
        |}
        |env {
        |  name: "SPARK_CONF_DIR"
        |  value: "/opt/spark/conf"
        |}
        |env {
        |  name: "EXTERNAL_CLUSTER_SUPPORT_ENABLED"
        |  value: "true"
        |}
        |env {
        |  name: "ARMADA_SPARK_DRIVER_SERVICE_NAME"
        |  value: "driverService"
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
        |volumeMounts {
        |}
        |imagePullPolicy: "IfNotPresent"
        |""".stripMargin

    val aca = new ArmadaClientApplication()
    val container = aca.getDriverContainer(driverServiceName,
      ClientArguments.fromCommandLineArgs(Array("--main-class", className)), sparkConf, Seq(new VolumeMount))
    val pstring = container.toProtoString
    assert(pstring == expectedString)
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