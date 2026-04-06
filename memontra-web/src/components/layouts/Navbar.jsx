import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import logo from '../../assets/images/logo-booth-second.png';

const Navbar = () => {
    const [isOpen, setIsOpen] = useState(false);

    const toggleMenu = () => {
        setIsOpen(!isOpen);
    };

    const navLinks = [
        { name: 'Beranda', href: '/' },
        { name: 'Fitur', href: '#fitur' },
        { name: 'Paket', href: '#paket' },
        { name: 'Galeri', href: '#galeri' },
        { name: 'Kontak', href: '#kontak' },
    ];

    return (
        <nav className="fixed w-full bg-universal/95 backdrop-blur-sm z-50 transition-all duration-300">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center h-20">

                    {/* Logo */}
                    <div className="shrink-0 flex items-center">
                        <a href="/">
                            <img src={logo} alt="Memontra Logo" className="w-40 h-auto" />
                        </a>
                    </div>

                    {/* Menu Desktop */}
                    <div className="hidden md:flex items-center space-x-8">
                        {navLinks.map((link, index) => (
                            <a
                                key={index}
                                href={link.href}
                                className="text-dark hover:text-primary font-medium transition-colors"
                            >
                                {link.name}
                            </a>
                        ))}

                    </div>
                    <div className="hidden md:flex items-center space-x-4">
                        <Link to="/login" className="bg-primary text-universal px-6 py-2 rounded-full font-semibold hover:bg-opacity-90 hover:scale-105 transition-all shadow-md shadow-primary/20">
                            Masuk
                        </Link>
                        <Link to="/register" className="bg-universal text-primary px-6 py-2 rounded-full border border-primary font-semibold hover:bg-opacity-90 hover:scale-105 transition-all shadow-md shadow-primary/20">
                            Daftar
                        </Link>
                    </div>

                    {/* Tombol Hamburger untuk Mobile */}
                    <div className="md:hidden flex items-center">
                        <button
                            onClick={toggleMenu}
                            className="text-primary hover:text-secondary focus:outline-none transition-colors p-2"
                        >
                            {/* Ikon Hamburger / Close (SVG murni biar nggak usah instal library icon dlu) */}
                            <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                {isOpen ? (
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                ) : (
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                                )}
                            </svg>
                        </button>
                    </div>
                </div>
            </div>

            {/* Menu Mobile (Dropdown) */}
            <div className={`md:hidden absolute w-full bg-universal shadow-lg transition-all duration-300 ease-in-out ${isOpen ? 'max-h-100 opacity-100 py-4' : 'max-h-0 opacity-0 overflow-hidden py-0'}`}>
                <div className="px-4 space-y-4  items-center flex flex-col">
                    {navLinks.map((link, index) => (
                        <a
                            key={index}
                            href={link.href}
                            onClick={() => setIsOpen(false)}
                            className="block px-3 py-2 text-base font-medium text-dark hover:text-primary hover:bg-primary/5 rounded-md transition-colors"
                        >
                            {link.name}
                        </a>
                    ))}

                </div>
                <div className="flex flex-col w-full justify-center py-4 gap-2 items-center">
                    <Link to="/login" className="bg-primary text-universal items-center px-6 py-2 rounded-full font-semibold hover:bg-opacity-90 hover:scale-105 transition-all shadow-md shadow-primary/20">
                        Masuk
                    </Link>
                    <Link to="/register" className="bg-universal text-primary px-6 py-2 rounded-full border border-primary font-semibold hover:bg-opacity-90 hover:scale-105 transition-all shadow-md shadow-primary/20">
                        Daftar
                    </Link>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;