A repo for testing Micronaut netty and poja performance with native image and systemd.

# Results

The image sizes are:
| | `demo-poja` | `demo-netty` |
| --- | --- | --- |
| MacOS GraalVM CE 21 | `44Mb` | `53Mb` |
| OL8 GraalVM CE 22 | `48Mb` | `60Mb` |
| OL8 GraalVM CE 22 `quickBuild=true` | `35Mb` | `43Mb` |
| MacOS GraalVM EE 21 | `45Mb` | `57Mb` |
| MacOS GraalVM EE 21 `quickBuild=true` | `36Mb` |  `43Mb` |

The time to first response (average over 100 runs):
| | `demo-poja` | `demo-netty` |
| --- | --- | --- |
| OL8 GraalVM CE 22 | `0.010920s` | `0.01372s` |
| OL8 GraalVM CE 22 `quickBuild=true` | `0.012086` | `0.015768s` |
| OL8 GraalVM CE 22 non-native image | `1.15598s` | `1.46136s` |

The OL8 instance is VM.Standard.E5.Flex 1 OCPU 16Gb:
* x86_64, `AMD EPYC 7J13 64-Core Processor`, 2 CPUs, 2445.404MHz

The memory usage measured with `pmap -X $(pgrep -f demo-poja | sed -n -e '1p') |  sed -n -e '2p;$p'`:
| | `demo-poja` | `demo-netty` |
| --- | --- | --- |
| OL8 GraalVM CE 22 RSS | `6556` | `6672` |
| OL8 GraalVM CE 22 PSS | `1097` | `1046` |

The memory usage measured with `top -o %MEM` in `RES` column is:
| | `demo-poja` | `demo-netty` |
| --- | --- | --- |
| OL8 GraalVM CE 22 before request | `35548` | `` |
| OL8 GraalVM CE 22 during request | `33556` | `` |
| OL8 GraalVM CE 22 after response | `35228` | `` |
| OL8 GraalVM CE 22 `quickBuild=true` before request | `28428` | `46360` |
| OL8 GraalVM CE 22 `quickBuild=true` during request | `28456` | `48192` |
| OL8 GraalVM CE 22 `quickBuild=true` after response | `29084` | `50740` |

Note, that the netty executable is not shutdown after response and is left around running.

# demo-poja

The project was created by selecting `graalvm`, `http-poja` and `slf4j-simple` in Micronaut Launcher.

Add the TestController.

Run (add `-Dnative.quickBuild=true` for quick native build):
```shell
cd demo-poja
./mvnw package -Dpackaging=native-image
cd ..

./test-poja.bash
```

GraalVM analysis:
```shell
Top 10 origins of code area:                                Top 10 object types in image heap:
  11.30MB java.base                                            6.38MB byte[] for code metadata
   1.42MB svm.jar (Native Image)                               3.44MB byte[] for java.lang.String
1013.65kB micronaut-inject-4.6.3.jar                           2.73MB java.lang.Class
 747.13kB reactor-core-3.6.9.jar                               2.31MB java.lang.String
 584.95kB micronaut-serde-support-2.11.0.jar                 899.25kB com.oracle.svm.core.hub.DynamicHubCompanion
 550.39kB micronaut-core-4.6.3.jar                           644.67kB byte[] for general heap data
 548.79kB micronaut-http-4.6.3.jar                           610.92kB byte[] for reflection metadata
 548.36kB jackson-core-2.17.2.jar                            496.60kB heap alignment
 338.45kB jdk.proxy4                                         490.51kB java.lang.Object[]
 332.82kB java.rmi                                           462.88kB java.lang.String[]
   2.68MB for 38 more packages                                 5.00MB for 2580 more object types

```

# demo-netty

The project was created by selecting `graalvm` and `slf4j-simple` in Micronaut Launcher.

Add the TestController and AppContextConfigurer.

Run (add `-Dnative.quickBuild=true` for quick native build):
```shell
cd demo-netty
./mvnw package -Dpackaging=native-image
cd ..

./test-netty.bash
```

GraalVM analysis:
```shell
Top 10 origins of code area:                                Top 10 object types in image heap:
  11.92MB java.base                                            8.06MB byte[] for code metadata
   1.50MB svm.jar (Native Image)                               4.04MB byte[] for java.lang.String
1018.07kB micronaut-inject-4.6.3.jar                           3.24MB java.lang.Class
 882.33kB reactor-core-3.6.9.jar                               2.66MB java.lang.String
 707.52kB netty-buffer-4.1.112.Final.jar                       1.05MB com.oracle.svm.core.hub.DynamicHubCompanion
 673.89kB micronaut-http-server-netty-4.6.3.jar              788.34kB byte[] for reflection metadata
 610.48kB netty-codec-http2-4.1.112.Final.jar                647.33kB byte[] for general heap data
 591.73kB netty-common-4.1.112.Final.jar                     602.90kB heap alignment
 587.75kB micronaut-serde-support-2.11.0.jar                 560.98kB java.lang.Object[]
 570.96kB micronaut-http-4.6.3.jar                           537.26kB java.lang.String[]
   5.67MB for 48 more packages                                 5.34MB for 2803 more object types
```


# Notes

You can change the `micronaut-maven-plugin` configuration with additional build args:

```xml
<plugin>
    <groupId>org.graalvm.buildtools</groupId>
    <artifactId>native-maven-plugin</artifactId>
    <configuration>
        <buildArgs combine.children="append">
            <!-- one of G1, serial (default), and epsilon -->
            <buildArg>--gc=serial</buildArg>
            <!--
             The install-exit-handlers option gives you the same signal handlers that a JVM does.
             This enables us to dump threa stack using kill -3 for example.
            -->
            <buildArg>--install-exit-handlers</buildArg>
            <buildArg>-H:+BuildReport</buildArg>
        </buildArgs>
        <quickBuild>${native.quickBuild}</quickBuild>
    </configuration>
</plugin>
```

To run the non-native image version build with
```shell
./mvnw package
```
and uncomment corresponding lines in the scripts.