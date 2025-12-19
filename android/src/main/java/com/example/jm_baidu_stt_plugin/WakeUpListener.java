package com.example.jm_baidu_stt_plugin;


public interface WakeUpListener {

    default void wakeUpStop() {
    }

    default void wakeUpSuccess(String result) {
    }

    default void wakeUpError() {
    }

    default void wakeAudio() {
    }

}
