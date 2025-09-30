android {
    compileSdk 34
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_21
        targetCompatibility JavaVersion.VERSION_21
    }
    
    kotlinOptions {
        jvmTarget = '21'
    }

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}