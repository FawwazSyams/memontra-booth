// src/sections/Hero.jsx
import React, { useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import AOS from 'aos';
import 'aos/dist/aos.css';
import { motion, useScroll, useTransform } from 'framer-motion';
import Typewriter from 'typewriter-effect';
import Antigravity from '../components/Antigravity';
import logo from '../assets/icon/logo-booth-only.png';

const Hero = () => {
    const containerRef = useRef(null);

    useEffect(() => {
        AOS.init({ duration: 800, once: true });
    }, []);

    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start start", "end start"]
    });

    const opacity = useTransform(scrollYProgress, [0, 0.4], [1, 0]);
    const yText = useTransform(scrollYProgress, [0, 1], [0, -100]);

    return (
        <section ref={containerRef} className="relative h-[200vh] w-full font-poppins bg-universal">

            {/* =========================================================
                AREA STICKY (Layar Pertama)
            ========================================================== */}
            <div className="sticky top-0 left-0 w-full h-screen flex flex-col items-center justify-center overflow-hidden z-0 px-4 sm:px-6 lg:px-8">

                {/* AREA ANTIGRAVITY */}
                <div className="absolute inset-0 w-full h-full z-0">
                    <Antigravity
                        count={300}
                        magnetRadius={6}
                        ringRadius={7}
                        waveSpeed={0.4}
                        waveAmplitude={1}
                        particleSize={1.5}
                        lerpSpeed={0.05}
                        color="#EFBF04"
                        autoAnimate
                        particleVariance={1}
                        rotationSpeed={0}
                        depthFactor={1}
                        pulseSpeed={3}
                        particleShape="capsule"
                        fieldStrength={10}
                    />
                </div>

                {/* Dekorasi Awan Blur */}
                <motion.div
                    animate={{ x: [0, 40, -20, 0], y: [0, -30, 20, 0], scale: [1, 1.1, 0.9, 1] }}
                    transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
                    className="absolute top-1/4 right-0 w-[30rem] md:w-[40rem] h-[30rem] md:h-[40rem] bg-primary/5 rounded-full blur-3xl -z-10"
                />
                <motion.div
                    animate={{ x: [0, -30, 30, 0], y: [0, 40, -20, 0], scale: [1, 1.2, 0.8, 1] }}
                    transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }}
                    className="absolute bottom-1/4 left-0 w-[20rem] md:w-[30rem] h-[20rem] md:h-[30rem] bg-secondary/5 rounded-full blur-3xl -z-10"
                />

                {/* =========================================================
                    AREA KONTEN TEKS UTAMA
                ========================================================= */}
                <motion.div
                    style={{ opacity, y: yText }}
                    className="relative z-10 max-w-5xl mx-auto text-center pointer-events-none"
                >
                    {/* Badge */}
                    <div data-aos="fade-down" className="inline-block px-5 py-1.5 tracking-wider">
                        <img src={logo} alt="Logo" className="w-20 h-20" />
                    </div>

                    {/* HEADLINE TYPEWRITER (Tanpa Kursor) */}
                    <h1 className="text-4xl sm:text-3xl md:text-4xl lg:text-6xl font-light text-primary leading-[1.1] mb-12 tracking-tight min-h-[3.5em] md:min-h-[3em]">
                        <Typewriter
                            onInit={(typewriter) => {
                                typewriter
                                    .pauseFor(500)
                                    .typeString('Abadikan Momen Sempurnamu dengan <span class="text-secondary">Sentuhan Emas</span>')
                                    .start();
                            }}
                            options={{
                                delay: 60,
                                cursor: '',
                                wrapperClassName: "text-primary",
                            }}
                        />
                    </h1>

                    {/* Tombol CTA */}
                    <div data-aos="fade-up" data-aos-delay="600" className="flex flex-col sm:flex-row justify-center gap-4 sm:gap-6 pointer-events-auto">
                        <Link to="/booking" className="bg-primary text-universal px-10 py-4 rounded-full font-bold transition-all duration-300 hover:bg-opacity-90 hover:-translate-y-1 shadow-lg shadow-primary/20 text-md">
                            Booking Now
                        </Link>
                        <a href="/photobooth" className="bg-universal border-2 border-primary text-primary px-10 py-4 rounded-full font-bold transition-all duration-300 hover:bg-primary hover:text-universal hover:-translate-y-1 text-md flex items-center justify-center gap-2">
                            Coba Photobooth Online
                        </a>
                    </div>
                </motion.div>
            </div>

            {/* Area scroll bawah */}
            <div className="h-screen w-full"></div>

        </section>
    );
};

export default Hero;