package com.example.jm_baidu_stt_plugin;


import java.util.List;

public interface AsrListener {

    default void asrReady() {
    }

    default void asrBegin() {
    }

    default void asrEnd() {
    }

    default void asrPartial(String result) {

    }

    default void asrFinalResult(List<String> result) {

    }

    default void asrPartialResult(List<String> result) {

    }

    default void asrFinish() {
    }

    default void asrErrorFinish() {
    }

    default void asrExit() {
    }

    default void asrVolume(int volumePercent,int volume) {
    }

    default void asrAudio() {
    }
}
