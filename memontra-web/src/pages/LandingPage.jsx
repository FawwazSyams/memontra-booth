import React from 'react';
import Navbar from '../components/layouts/Navbar';
import Hero from '../sections/Hero';
import Features from '../sections/Features'
import Pricing from '../sections/Pricing';
import Gallery from '../sections/Gallery';
import Contact from '../sections/Contact';
import Footer from '../components/layouts/Footer';
import { useAuth } from '../context/AuthContext';
import UserDashboard from './UserDashboard';

const LandingPage = () => {
    const { user, isLoading } = useAuth();

    // Tampilkan loading screen sederhana jika masih mengecek auth state
    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-primary/5">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    // Jika user sudah login, tampilkan halaman khusus (User Dashboard)
    if (user) {
        return <UserDashboard />;
    }

    // Jika belum login, tampilkan Landing Page default
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