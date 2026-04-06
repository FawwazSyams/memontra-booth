import React from 'react';
import Navbar from '../components/layouts/Navbar';
import Hero from '../sections/Hero';
import Features from '../sections/Features'
import Pricing from '../sections/Pricing';
import Gallery from '../sections/Gallery';
import Contact from '../sections/Contact';
import Footer from '../components/layouts/Footer';

const LandingPage = () => {
    return (
        <div className="flex flex-col min-h-screen">
            <Navbar />

            {/* main otomatis mengisi ruang kosong agar footer selalu di bawah */}
            <main className="grow">
                <Hero />
                <Features />
                <Pricing />
                <Gallery />
                <Contact />
            </main>

            <Footer />
        </div>
    );
};

export default LandingPage;